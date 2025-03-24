module Trailblazer
  module Operation::PublicCall
    # TODO: add docs from original {Operation.call}.
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
      signal, (ctx, flow_options) = self.__(self, options, initial_wrap_static: INITIAL_WRAP_STATIC, **options_for_invoke) # Operation.__ is defined via {trailblazer-invoke}. It's the "canonical invoke".

      Operation::Railway::Result(signal, ctx, flow_options)
    end

    # This TaskWrap step replaces the default {call_task} step for this very operation.
    # Instead of invoking the operation using {Operation.call}, it does {Operation.call_with_circuit_interface},
    # so we don't invoke {Operation.call} twice.
    #
    # I don't really like this "hack", but it's the only way until we get method overloading.
    #
    # @private
    def self.call_operation_with_circuit_interface(wrap_ctx, original_args) # DISCUSS: copied from {TaskWrap.call_task}.
      operation = wrap_ctx[:task]

      original_arguments, original_circuit_options = original_args

      # Call the actual operation, but directly using {#strategy_call} using the circuit-interface.
      return_signal, return_args = operation.strategy_call(original_arguments, **original_circuit_options)

      # DISCUSS: do we want original_args here to be passed on, or the "effective" return_args which are different to original_args now?
      wrap_ctx = wrap_ctx.merge(return_signal: return_signal, return_args: return_args)

      return wrap_ctx, original_args
    end

    initial_wrap_static_for_activity = Invoke.initial_wrap_static
    # raise initial_wrap_static_for_activity.inspect
    in_extension = initial_wrap_static_for_activity[0]

    # Replace the TaskWrap's {call_task} step with our step that doesn't do {Create.call} but {Create.strategy_call}.
    INITIAL_WRAP_STATIC = [
      in_extension,
      Activity::TaskWrap::Pipeline.Row("task_wrap.call_task", method(:call_operation_with_circuit_interface))
    ]
  end
end
