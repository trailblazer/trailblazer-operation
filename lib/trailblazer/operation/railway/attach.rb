module Trailblazer
  module Operation::Railway
    # WARNING: The API here is still in a state of flux since we want to provide a simple yet flexible solution.
    # This is code executed at compile-time and can be slow.
    # @note `__sequence__` is a private concept, your custom DSL code should not rely on it.


    # DRAFT
    #  direction: "(output) signal"

    # document ## Outputs
    #   task/acti has outputs, role_to_target says which task output goes to what next task in the composing acti.

    module DSL
      module Attach
        def attach(task, options={})
          # we only want allow a task here?

          # default_options = {
          #   source:
          #   edge:
          #   target: [ task, id: options[:id] ]
          # }

          # # or use insert! here?
          #                     # simulate macro here
          # add_step_or_task!( { task: task }, user_options, :attach )
        end
      end
    end
  end
end
