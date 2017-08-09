module Trailblazer
  module Operation::Railway
    # every step is wrapped by this proc/decider. this is executed in the circuit as the actual task.
    # Step calls step.(options, **options, flow_options)
    # Output direction binary: true=>Right, false=>Left.
    # Passes through all subclasses of Direction.~~~~~~~~~~~~~~~~~
    module TaskBuilder
      class Task < Proc
        def initialize(source_location, &block)
          @source_location = source_location
          super &block
        end

        def to_s
          "<Railway::Task{#{@source_location}}>"
        end

        def inspect
          to_s
        end
      end

      def self.call(step, on_true=Circuit::Right, on_false=Circuit::Left)
        Task.new step, &->(direction, options, flow_options) do
          # Execute the user step with TRB's kw args.
          result = Trailblazer::Option::KW(step).(options, **flow_options)

          # Return an appropriate signal which direction to go next.
          direction = binary_direction_for(result, on_true, on_false)

          [ direction, options, flow_options ]
        end
      end

      def self.binary_direction_for(result, on_true, on_false)
        result.is_a?(Class) && result < Circuit::Direction ? result : (result ? on_true : on_false)
      end
    end
  end
end
