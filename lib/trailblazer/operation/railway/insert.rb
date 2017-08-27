module Trailblazer
  module Operation::Railway
    # document ## Outputs
    #   task/acti has outputs, role_to_target says which task output goes to what next task in the composing acti.

    module Insert
      def self.call(id, default_task_outputs:raise, **insertion_options)
        insertion_options =
          { # defaults
            outputs: default_task_outputs,
          }.
          merge(insertion_options)

        options, _ = insertion_args_for( insertion_options )

        wirings = insertion_wirings_for( options ) # TODO: this means macro could say where to insert?
      end

      def self.insertion_args_for(task:raise, node_data:raise, insert_before:raise, outputs:raise, connect_to:raise, **passthrough)
        # something like *** would be cool
        return {
          task:          task,
          node_data:     node_data,
          insert_before: insert_before,
          outputs:       outputs,
          connect_to:    connect_to
        }.freeze
      end


      # insert_before: "End.success",
      # outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure } }, # any outputs and their polarization, generic.
      # mappings:      { success: "End.success", failure: "End.myend" } # where do my task's outputs go?
      # always adds task on a track edge.
      # @return ElementWiring
      def self.insertion_wirings_for(task: nil, insert_before:raise, outputs:{}, connect_to:{}, node_data:raise)
        raise "missing node_data: { id: .. }" if node_data[:id].nil?

        wirings = []

        wirings << [:insert_before!, insert_before, incoming: ->(edge) { edge[:type] == :railway }, node: [ task, node_data ] ]

        # FIXME: don't mark pass_fast with :railway
        raise "bla no outputs remove me at some point " unless outputs.any?
        wirings += DSL::Wirings.task_outputs_to(outputs, connect_to, node_data[:id], type: :railway) # connect! for task outputs

        wirings # embraces all alterations for one "step".
      end
    end # Insert
  end
end
