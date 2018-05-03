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
      ctx = Operation::PublicCall.options_for_public_call(*args)

      # call the activity.
      # This will result in invoking {::call_with_circuit_interface}.
      last_signal, (options, flow_options) = Activity::TaskWrap.invoke(self, [ctx, {}], {})

      # Result is successful if the activity ended with an End event derived from Railway::End::Success.
      Operation::Railway::Result(last_signal, options, flow_options)
    end

    # This interface is used for all nested OPs (and the outer-most, too).
    def call_with_circuit_interface(args, circuit_options)
      @activity.(
        args,
        circuit_options.merge(
          exec_context: new
        )
      )
    end

    # Compile a Context object to be passed into the Activity::call.
    # @private
    def self.options_for_public_call(options={}, *containers)
      # generate the skill hash that embraces runtime options plus potential containers, the so called Runtime options.
      # This wrapping is supposed to happen once in the entire system.

      hash_transformer = ->(containers) { containers[0].to_hash } # FIXME: don't transform any containers into kw args.

      immutable_options = Trailblazer::Context::ContainerChain.new( [options, *containers], to_hash: hash_transformer ) # Runtime options, immutable.

      ctx = Trailblazer::Context(immutable_options)
    end
  end
end
