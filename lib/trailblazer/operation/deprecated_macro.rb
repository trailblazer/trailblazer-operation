# TODO: REMOVE IN 2.2.
module Trailblazer
  module Operation::Railway
    module DSL
      # Allows old macros with the `(input, options)` signature.
      module DeprecatedMacro
        def add_step_or_task!(proc, *args)
          return super unless proc.is_a?(Array)

          _proc, node_data = *proc
          node_data = node_data.merge( id: node_data[:name] ) if node_data[:name]

          warn %{[Trailblazer] Macros with API (input, options) are deprecated. Please use the "Task API" signature (direction, options, flow_options) or use a simpler Callable. (#{proc})}
          __proc = ->(direction, options, flow_options) do
            result    = _proc.(flow_options[:exec_context], options) # run the macro, with the deprecated signature.
            direction = TaskBuilder.binary_direction_for(result, Circuit::Right, Circuit::Left)

            [ direction, options, flow_options ]
          end

          super({ task: __proc, node_data: node_data }, *args)
        end
      end # DeprecatedMacro
    end
  end
end
