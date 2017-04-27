module Trailblazer
  module Operation::Railway
    # Insert a step into the Activity's circuit
    # and transform a Sequence into an Activity.
    # @api private
    module Activity
      module_function
      # every step is wrapped by this proc/decider. this is executed in the circuit as the actual task.
      # Step calls step.(options, **options, flow_options)
      # Output direction binary: true=>Right, false=>Left.
      # Passes through all subclasses of Direction.~~~~~~~~~~~~~~~~~
      def Step(step, on_true, on_false)
        ->(direction, options, flow_options) do
          # Execute the user step with TRB's kw args.
          result = Circuit::Task::Args::KW(step).(direction, options, flow_options)

          # Return an appropriate signal which direction to go next.
          direction = result.is_a?(Class) && result < Circuit::Direction ? result : (result ? on_true : on_false)
          [ direction, options, flow_options ]
        end
      end
    end
  end
end
