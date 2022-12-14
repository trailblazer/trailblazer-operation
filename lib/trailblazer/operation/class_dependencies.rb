# Dependencies can be defined on the operation. class level
class Trailblazer::Operation
  # The use of this module is currently not encouraged and it is only here for backward-compatibility.
  # Instead, please pass dependencies via containers, locals, or macros into the respective steps.
  #
  module ClassDependencies
    def [](field)
      class_fields[field]
    end

    # Store a field on @state, which is provided by {Strategy}.
    def []=(field, value)
      @state.update!(:fields) do |fields|
        fields.merge(field => value)
      end
    end

    def options_for_public_call(options, flow_options)
      ctx = super
      context_for_fields(class_fields, [ctx, flow_options])
    end

    private def class_fields
      @state.get(:fields)
    end

    private def context_for_fields(fields, (ctx, flow_options), **)
      ctx_with_fields = Trailblazer::Context(fields, ctx, flow_options[:context_options]) # TODO: redundant to options_for_public_call.
    end

    def call_with_circuit_interface((ctx, flow_options), **circuit_options)
      ctx_with_fields = context_for_fields(class_fields, [ctx, flow_options], **circuit_options)

      super([ctx_with_fields, flow_options], **circuit_options) # FIXME: should we unwrap here?
    end
  end
end
