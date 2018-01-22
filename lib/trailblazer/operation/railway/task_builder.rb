module Trailblazer
  module Operation::Railway
    # every step is wrapped by this proc/decider. this is executed in the circuit as the actual task.
    # Step calls step.(options, **options, flow_options)
    # Output direction binary: true=>Right, false=>Left.
    # Passes through all subclasses of Direction.~~~~~~~~~~~~~~~~~
    module TaskBuilder
      def self.call(user_proc)
        Task.new( Trailblazer::Option::KW( user_proc ), user_proc )
      end

      # Translates the return value of the user step into a valid signal.
      # Note that it passes through subclasses of {Signal}.
      def self.binary_direction_for(result, on_true, on_false)
        result.is_a?(Class) && result < Activity::Signal ? result : (result ? on_true : on_false)
      end
    end

    class Task
      def initialize(task, user_proc)
        @task      = task
        @user_proc = user_proc
        freeze
      end

      def call( (options, *args), **circuit_args )
        # Execute the user step with TRB's kw args.
        result = @task.( options, **circuit_args ) # circuit_args contains :exec_context.

        # Return an appropriate signal which direction to go next.
        direction = TaskBuilder.binary_direction_for( result, Activity::Right, Activity::Left )

        [ direction, [ options, *args ], **circuit_args ]
      end
    end
  end
end
