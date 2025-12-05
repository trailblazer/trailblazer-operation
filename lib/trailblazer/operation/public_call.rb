module Trailblazer
  module Operation::PublicCall
    # TODO: add docs from original {Operation.call}.
    def call(options = {}, flow_options = nil, circuit_options = {}, **kwargs, &block)
      return strategy_call(options, flow_options, circuit_options) if ! flow_options.nil? # This is kind of a hack that could be well hidden if Ruby had method overloading. Goal is to simplify the call thing as we're fading out Operation::public_call anyway.

      # DISCUSS: move to separate method?
      # normalize options:
      options = options.merge(kwargs) # when using Op.call(params:, ...), we need to merge {kwargs} (?).

      invoke_with_public_interface(options, &block)
    end

    def invoke_with_public_interface(options, **options_for_invoke, &block) # FIXME: where can we pass {options_for_invoke}?
      # On the top level, use {#__}.
      options_for_invoke = {matcher_context: block.binding.receiver}.merge(options_for_invoke) if block # DISCUSS: do we always want that?

      options_for_invoke = options_for_invoke.merge(
        normalizer_options: {
          Operation.Extension() => NORMALIZER_TASK_WRAP_EXTENSIONS_FOR_PUBLIC_CALL_TASK
        }
      )

      ctx, flow_options, signal = self.__(self, options, **options_for_invoke, &block) # Operation.__ is defined via {trailblazer-invoke}. It's the "canonical invoke".

      Operation::Railway::Result(signal, ctx, flow_options)
    end

    # NOTE: mostly copied from {Activity::TaskWrap.call_task}.
    #
    # This TaskWrap step replaces the default {call_task} step for this very operation.
    # Instead of invoking the operation using {Operation.call}, it does {Operation.call_with_circuit_interface},
    # so we don't invoke {Operation.call} twice.
    #
    # @private
    def self.call_operation_with_circuit_interface(wrap_ctx, flow_options, _)
      operation = wrap_ctx[:task]
# FIXME: use as much logic from call_task as possible.
      # Call the actual operation, but directly using {#strategy_call} using the circuit-interface.
      return_ctx, flow_options, return_signal = operation.strategy_call(wrap_ctx[:application_ctx], flow_options, wrap_ctx[:application_circuit_options])

      # DISCUSS: do we want original_args here to be passed on, or the "effective" return_args which are different to original_args now?
      wrap_ctx = wrap_ctx.merge(return_signal: return_signal, return_ctx: return_ctx)

      return wrap_ctx, flow_options
    end

    # Replace the TaskWrap's {call_task} step with our step that doesn't do {Create.call} but {Create.strategy_call}.
    NORMALIZER_TASK_WRAP_EXTENSIONS_FOR_PUBLIC_CALL_TASK = Activity::TaskWrap::Extension(
      [
        method(:call_operation_with_circuit_interface),
        id: "task_wrap.call_task",
        replace: "task_wrap.call_task"
      ]
    )
  end
end
