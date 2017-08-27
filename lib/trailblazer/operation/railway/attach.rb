module Trailblazer
  module Operation::Railway
    module Attach
      module DSL
        def attach(task, user_options={})
          # we only want allow a task here?
          macro = { task: task, node_data: { id: task } } # id should get overridden from user_options.

          add_step_or_task!( macro, user_options, alteration: Attach, type: :attach, task_builder: TaskBuilder )
        end
      end

      # @return Array wirings
      def self.call(id, task:, node_data:, **attach_options)
        [
          [ :attach!, target: [task, node_data], edge: [Circuit::Left, {}], source: "Start.default" ]
        ]
      end
    end
  end
end
