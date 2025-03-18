module Trailblazer
  module Operation::PublicCall
    def call(options = {}, flow_options = {}, **circuit_options)
      return strategy_call(options, **circuit_options) if options.is_a?(Array) # This is kind of a hack that could be well hidden if Ruby had method overloading. Goal is to simplify the call thing as we're fading out Operation::public_call anyway.

      # DISCUSS: move to separate method?
      # normalize options:
      options = options.merge(circuit_options) # when using Op.call(params:, ...), {circuit_options} will always be ctx variables.

      invoke_with_public_interface(options)
    end

    # TODO: we always use {self.__} as a canonical invoke.
    def invoke_with_public_interface(options, **options_for_invoke)
      # Only use {#__} on the top level.
      signal, (ctx, flow_options) = self.__(self, options, **options_for_invoke) # Operation.__ is defined via {trailblazer-invoke}. It's the "canonical invoke".

      Operation::Railway::Result(signal, ctx, flow_options)
    end
  end
end
