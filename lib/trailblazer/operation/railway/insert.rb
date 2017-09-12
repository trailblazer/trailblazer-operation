module Trailblazer
  module Operation::Railway
    # document ## Outputs
    #   task/acti has outputs, role_to_target says which task output goes to what next task in the composing acti.

    module Insert
      module DSL
        # The `insert` alteration returns wirings array consisting of [ :insert_before, :connect, :connect, .. ]
        def insert(step, **user_options)
          _element( step, user_options, { alteration: Insert, type: :insert, task_builder: TaskBuilder } )
        end
      end

      def self.call(id, **insertion_options)
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
      # connect_to:    { success: "End.success", failure: "End.myend" } # where do my task's outputs go?
      # always adds task on a track edge.
      # @return [Array]
      def self.insertion_wirings_for(task: nil, insert_before:raise, outputs:{}, connect_to:{}, node_data:raise)
        raise "missing node_data: { id: .. }" if node_data[:id].nil?

        wirings = []

        wirings << [:insert_before!, insert_before, incoming: ->(edge) { edge[:type] == :railway }, node: [ task, node_data ] ]

        # FIXME: don't mark pass_fast with :railway
        raise "bla no outputs remove me at some point " unless outputs.any?
        wirings += task_outputs_to(outputs, connect_to, node_data[:id], type: :railway) # connect! for task outputs

        wirings # embraces all alterations for one "step".
      end

      # @private
      # connect! statements connecting `task_outputs` with `known_targets`.
      # @param known_targets Hash {  }
      def self.task_outputs_to(task_outputs, known_targets, id, edge_options)
        # task_outputs is what the task has
        # known_targets are ends this activity/operation provides.
        task_outputs.collect do |signal, role:raise|
          target = known_targets[ role ] or raise "Couldn't map output role #{role.inspect} for #{known_targets.inspect}"

          # TODO: add more options to edge like role: :success or role: pass_fast.

          [:connect!, source: id, edge: [signal, edge_options], target: target ] # e.g. "Left --> End.failure"
        end
      end
    end # Insert
  end
end
