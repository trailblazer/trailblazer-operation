# Dependencies can be defined on the operation. class level
class Trailblazer::Operation
  # The use of this module is currently not encouraged and it is only here for backward-compatibility.
  # Instead, please pass dependencies via containers, locals, or macros into the respective steps.
  module ClassDependencies
    def [](field)
      @state.to_h[:fields][field]
    end

    def []=(field, value)
      options = @state.to_h[:fields].merge(field => value)
      @state.update_options(options)
    end

    def options_for_public_call(options, flow_options)
      ctx = super
      context_for_fields(class_fields, [ctx, flow_options])
    end

    private def class_fields
      @state.to_h[:fields]
    end

    private def context_for_fields(fields, (ctx, flow_options), **)
      ctx_with_fields = Trailblazer::Context(fields, ctx, flow_options[:context_options]) # TODO: redundant to otions_for_public_call.
    end

    def call_with_circuit_interface((ctx, flow_options), **circuit_options)
      ctx_with_fields = context_for_fields(class_fields, [ctx, flow_options], **circuit_options)

      super([ctx_with_fields, flow_options], **circuit_options) # FIXME: should we unwrap here?
    end
  end
end
