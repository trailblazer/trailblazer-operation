module Trailblazer
  module Operation::Railway
    module Attach
      def attach(task, user_options={})
        # we only want allow a task here?
        macro = { task: task, node_data: { id: task } } # id should get overridden from user_options.

        _element( macro, user_options, { alteration: Attach, type: :attach, task_builder: TaskBuilder } )
      end

      # @return Array wirings
      def self.call(id, task:raise, node_data:raise, **attach_options)
        [
          [ :attach!, target: [task, node_data], edge: [Circuit::Left, {}], source: "Start.default" ]
        ]
      end
    end
  end
end
