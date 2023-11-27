module Trailblazer
  module Operation::PublicCall
    # This is the outer-most public `call` method that gets invoked when calling `Create.()`.
    # The signature of this is `params, options, *containers`. This was a mistake, as the
    # first argument could've been part of `options` hash in the first place.
    #
    # Create.(params, runtime_data, *containers)
    #   #=> Result<Context...>
    #
    # In workflows/Nested compositions, this method is not used anymore and it might probably
    # get removed in future versions of TRB. Currently, we use Operation::__call__ as an alternative.
    #
    #
    # @note Do not override this method as it will be removed in future versions. Also, you will break tracing.
    # @return Operation::Railway::Result binary result object
    def call(options = {}, flow_options = {}, **circuit_options)
      return call_with_circuit_interface(options, **circuit_options) if options.is_a?(Array) # This is kind of a hack that could be well hidden if Ruby had method overloading. Goal is to simplify the call thing as we're fading out Operation::public_call anyway.

      call_with_public_interface_from_call(options, flow_options, **circuit_options)
    end

    # @private Please do not override this method as it might get removed.
    def call_with_public_interface_from_call(options, flow_options, **circuit_options)
      # normalize options.
      options = options
        .merge(circuit_options) # when using Op.call(params:, ...), {circuit_options} will always be ctx variables.

      call_with_public_interface(options, flow_options)
    end

    # Default {@activity} call interface which doesn't accept {circuit_options}
    #
    # @param [Array] args => [ctx, flow_options]
    #
    # @return [Operation::Railway::Result]
    #
    # @semi-public It's OK to override this method.
    def call_with_public_interface(options, flow_options, invoke_class: Activity::TaskWrap, **circuit_options)
      flow_options  = flow_options_for_public_call(flow_options)

      # In Ruby < 3, calling Op.(params: {}, "current_user" => user) results in both {circuit_options} and {options} containing variables.
      # In Ruby 3.0, **circuit_options is always empty.
      # options       = circuit_options.any? ? circuit_options.merge(options) : options

      ctx           = options_for_public_call(options, flow_options)

      # Call the activity as it if was a step in an endpoint.

      # This will result in invoking {self.call_with_circuit_interface}.
      signal, (ctx, flow_options) = invoke_class.invoke(
        self,
        [ctx, flow_options],
        container_activity: Activity::TaskWrap.container_activity_for(self, wrap_static: initial_wrap_static), # we cannot make this static because of {self} unless we override {#inherited}.
        **circuit_options
      )

      # Result is successful if the activity ended with an End event derived from Railway::End::Success.
      Operation::Railway::Result(signal, ctx, flow_options)
    end

    # This interface is used for all nested OPs (and the outer-most, too).
    #
    # @param [Array] args - Contains [ctx, flow_options]
    # @param [Hash]  circuit_options - Options to configure activity circuit
    #
    # @return [signal, [ctx, flow_options]]
    #
    # @private
    def call_with_circuit_interface(args, **circuit_options)
      strategy_call(args, **circuit_options) # FastTrack#call
    end

    def options_for_public_call(*args)
      Operation::PublicCall.options_for_public_call(*args)
    end

    # Compile a Context object to be passed into the Activity::call.
    # @private
    def self.options_for_public_call(options, flow_options = {})
      Trailblazer::Context(options, {}, flow_options[:context_options])
    end

    # @semi=public
    def flow_options_for_public_call(options = {})
      options
    end

    # TODO: remove when we stop supporting < 3.0.
    #       alternatively, ctx aliasing is only available for Ruby > 2.7.
    def call_with_flow_options(options, flow_options)
      raise "[Trailblazer] `Operation.call_with_flow_options is deprecated in Ruby 3.0. Use `Operation.(options, flow_options)`" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0.0")
      call_with_public_interface(options, flow_options, {invoke_class: Activity::TaskWrap})
    end

    # This TaskWrap step replaces the default {call_task} step for this very operation.
    # Instead of invoking the operation using {Operation.call}, it does {Operation.call_with_circuit_interface},
    # so we don't invoke {Operation.call} twice.
    #
    # I don't really like this "hack", but it's the only way until we get method overloading.
    #
    # @private
    def self.call_task(wrap_ctx, original_args) # DISCUSS: copied from {TaskWrap.call_task}.
      operation = wrap_ctx[:task]

      original_arguments, original_circuit_options = original_args

      # Call the actual task we're wrapping here.
      # puts "~~~~wrap.call: #{task}"
      return_signal, return_args = operation.call_with_circuit_interface(original_arguments, **original_circuit_options)

      # DISCUSS: do we want original_args here to be passed on, or the "effective" return_args which are different to original_args now?
      wrap_ctx = wrap_ctx.merge(return_signal: return_signal, return_args: return_args)

      return wrap_ctx, original_args
    end

    INITIAL_WRAP_STATIC = Activity::TaskWrap::Pipeline.new([Activity::TaskWrap::Pipeline.Row("task_wrap.call_task", method(:call_task))])

    def initial_wrap_static
      INITIAL_WRAP_STATIC
    end
  end
end
