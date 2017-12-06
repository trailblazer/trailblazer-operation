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

# TODO: make this class replaceable so @Mensfeld gets his own call style. :trollface:

      def self.call(step, on_true=Activity::Right, on_false=Activity::Left)
        Task.new step, &->( (options, *args), **circuit_args ) do
          # Execute the user step with TRB's kw args.
          result = Trailblazer::Option::KW(step).(options, **circuit_args) # circuit_args contains :exec_context.

          # Return an appropriate signal which direction to go next.
          direction = binary_direction_for(result, on_true, on_false)

          [ direction, [ options, *args ], **circuit_args ]
        end
      end

      # Translates the return value of the user step into a valid signal.
      # Note that it passes through subclasses of {Signal}.
      def self.binary_direction_for(result, on_true, on_false)
        result.is_a?(Class) && result < Activity::Signal ? result : (result ? on_true : on_false)
      end
    end
  end
end
