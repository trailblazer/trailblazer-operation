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
    # get removed in future versions of TRB. Currently, we use Activity::__call__ as an alternative.
    #
    # @return Operation::Railway::Result binary result object
    def call(params={}, options={}, *containers)
      options = options.merge("params" => params) # options will be passed to all steps/activities.

      # generate the skill hash that embraces runtime options plus potential containers, the so called Runtime options.
      # This wrapping is supposed to happen once in the entire system.

      hash_transformer = ->(containers) { options.to_hash } # FIXME: don't transform any containers into kw args.

      immutable_options = Trailblazer::Context::ContainerChain.new([options, *containers], to_hash: hash_transformer) # Runtime options, immutable.

      direction, options, flow_options = super(immutable_options) # DISCUSS: this could be ::call_with_context.

      # Result is successful if the activity ended with an End event derived from Railway::End::Success.
      Railway::Result(direction, options, flow_options)
    end
  end
end


