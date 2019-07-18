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
    def call(*args)
      return call_with_circuit_interface(*args) if args.any? && args[0].is_a?(Array) # This is kind of a hack that could be well hidden if Ruby had method overloading. Goal is to simplify the call/__call__ thing as we're fading out Operation::call anyway.

      call_with_public_interface(*args)
    end

    def call_with_public_interface(*args)
      ctx = options_for_public_call(*args)

      # call the activity.
      # This will result in invoking {::call_with_circuit_interface}.
      # last_signal, (options, flow_options) = Activity::TaskWrap.invoke(self, [ctx, {}], {})
      signal, (ctx, flow_options) = Activity::TaskWrap.invoke(
        @activity,
        [ctx, {}],
        exec_context: new
      )

      # Result is successful if the activity ended with an End event derived from Railway::End::Success.
      Operation::Railway::Result(signal, ctx, flow_options)
    end

    # This interface is used for all nested OPs (and the outer-most, too).
    def call_with_circuit_interface(args, circuit_options)
      strategy_call(args, circuit_options) # FastTrack#call
    end

    def options_for_public_call(*args)
      Operation::PublicCall.options_for_public_call(*args)
    end

    # Compile a Context object to be passed into the Activity::call.
    # @private
    def self.options_for_public_call(options={})
      Trailblazer::Context.for(options, [options, {}], {})
    end
  end
end
