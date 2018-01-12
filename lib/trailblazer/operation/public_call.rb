class Trailblazer::Operation
  module PublicCall
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
      ctx = PublicCall.options_for_public_call(*args)

      # call the activity.
      last_signal, (options, flow_options) = __call__( [ctx, {}] ) # Railway::call # DISCUSS: this could be ::call_with_context.

      # Result is successful if the activity ended with an End event derived from Railway::End::Success.
      Railway::Result(last_signal, options, flow_options)
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
