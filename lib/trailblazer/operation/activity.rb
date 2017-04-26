module Trailblazer
  module Operation::Railway
    # Insert a step into the Activity's circuit
    # and transform a Sequence into an Activity.
    # @api private
    module Activity
      module_function
      # idea: those methods could live somewhere else.
      StepArgs = Struct.new(:original_args, :incoming_direction, :connections, :args_for_Step, :insert_before)
      StepRow = Struct.new(:step, :options, *Activity::StepArgs.members) # step, original_args, incoming_direction, ...

      # Helpers to create StepArgs{} for ::for.
      def args_for_pass(activity, *args); StepArgs.new( args, Circuit::Right, [],                                                   [Circuit::Right, Circuit::Right], activity[:End, :right] ); end
      def args_for_fail(activity, *args); StepArgs.new( args, Circuit::Left,  [],                                                   [Circuit::Left, Circuit::Left], activity[:End, :left] ); end
      def args_for_step(activity, *args); StepArgs.new( args, Circuit::Right, [[ Circuit::Left, activity[:End, :left] ]], [Circuit::Right, Circuit::Left], activity[:End, :right] ); end

      # @api private
      # 1. Processes the step API's options (such as `:override` of `:before`).
      # 2. Uses `Sequence.alter!` to maintain a linear array representation of the circuit's tasks.
      #    This is then transformed into a circuit/Activity. (We could save this step with some graph magic)
      # 3. Returns a new Activity instance.
      def for(sequence, activity, step_config) # recalculate circuit.
        proc, options = step_config.original_args

        _proc, _options = normalize_args(proc, options)
        options = _options.merge(options)
        options = options.merge(replace: options[:name]) if options[:override] # :override

        step    = Step(_proc, *step_config.args_for_Step)
        step = deprecate_input_for_macro!(proc, _proc, options, step)

        # DISCUSS: the problem here is that sequence is mutated, which is not clearly visible.
        # insert Step into Sequence (append, replace, before, etc.)
        row = StepRow.new(step, options, *step_config)
        sequence.alter!(options, row)

        # convert Sequence to new Activity.
        sequence.to_activity(activity)
      end

      # @api private
      # Decompose single array from macros or set default name for user step.
      def normalize_args(proc, options)
        proc.is_a?(Array) ?
          proc :                   # macro
          [ proc, { name: proc } ] # user step
      end

      def deprecate_input_for_macro!(proc, _proc, options, step) # TODO: REMOVE IN 2.2.
        return step unless proc.is_a?(Array)
        return step unless _proc.arity == 2 # FIXME: what about callable objects?
        # FIXME: what about :context with Wrap?
        warn "[Trailblazer] Macros with API (input, options) are deprecated. Please use the signature (options, **) just like in normal steps."
        DeprecatedMacro(_proc, Circuit::Right, Circuit::Left)
      end

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

      def DeprecatedMacro(step, on_true, on_false) # TODO: REMOVE IN 2.2.
        ->(direction, options, flow_options) do
          # Execute the user step with TRB's kw args.
          # result = Circuit::Task::Args::KW(step).(direction, options, flow_options)
          result = step.(flow_options[:context], options)

          # Return an appropriate signal which direction to go next.
          direction = result.is_a?(Class) && result < Circuit::Direction ? result : (result ? on_true : on_false)
          [ direction, options, flow_options ]
        end
      end
    end
  end
end
