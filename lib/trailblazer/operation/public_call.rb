class Trailblazer::Operation
  module PublicCall
    # This is the outer-most public `call` method that gets invoked when calling `Create.()`.
    # The signature of this is `params, options, *containers`. This was a mistake, as the
    # first argument could be part of `options` in the first place.
    #
    # In workflows/Nested compositions, this method is not used anymore and it might probably
    # get removed in future versions of TRB.
    #
    # @returns Operation::Result binary result object
    def call(params={}, options={}, *containers)
      options = options.merge("params" => params)

      direction, options, flow_options = super(options, *containers)   # FIXME: should we return the Result object here?

      # Result is successful if the activity ended with the "right" End event.
      Railway::Result(direction, options)
    end
  end
end


