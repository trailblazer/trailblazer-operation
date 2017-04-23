require "trailblazer/operation/result"
require "trailblazer/circuit"

module Trailblazer
  # Operations is simply a thin API to define, inherit and run circuits by passing the options object.
  # It encourages the linear railway style (http://trb.to/gems/workflow/circuit.html#operation) but can
  # easily be extend for more complex workflows.
  class Operation
    # End event: All subclasses of End:::Success are interpreted as "success"?
    module Railway
      def self.included(includer)
        includer.extend ClassMethods # ::call, ::inititalize_pipetree!
        includer.extend DSL

        includer.initialize_activity!
      end

      # This is code run at compile-time and can be slow.
      module DSL
        def success(proc, options={}); add( args_for_pass(self["__activity__"], proc, options) ); end
        def failure(proc, options={}); add( args_for_fail(self["__activity__"], proc, options) ); end
        def step   (proc, options={}); add( args_for_step(self["__activity__"], proc, options) ); end

        # hooks to override. TODO: make this cooler.
        def args_for_pass(*args); Activity.args_for_pass(*args); end
        def args_for_fail(*args); Activity.args_for_fail(*args); end
        def args_for_step(*args); Activity.args_for_step(*args); end

      private
        def add(step_args)
          heritage.record(:add, step_args)

          self["__activity__"] = Activity.for(self["__railway__"], self["__activity__"], step_args)
        end
      end # DSL

      module ClassMethods
        # Top-level, this method is called when you do Create.() and where
        # all the fun starts, ends, and hopefully starts again.
        def call(options)
          activity = self["__activity__"] # FIXME: rename to activity, deprecate ["__activity__"].inspect

          last, operation, flow_options = activity.(activity[:Start], options, context: new) # TODO: allow different context.

          # Result is successful if the activity ended with the "right" End event.
          Result.new(last.kind_of?(End::Success), options)
        end

        def initialize_activity!
          heritage.record :initialize_activity!

          self["__railway__"]  = Sequence.new
          self["__activity__"] = InitialActivity()
        end

        private
        # The initial Activity with no-op wiring.
        def InitialActivity
          # mutable declarative data structure to collect all events for an operation's Circuit.
          events  = {
            end: {
              right: End::Success.new(:right),
              left:  End::Failure.new(:left)
            }
          }

          Circuit::Activity({}, events) do |evt|
            { evt[:Start] => { Circuit::Right => evt[:End, :right], Circuit::Left => evt[:End, :left] } }
          end
        end
        # attr_reader :__activity__
      end

      # Data object: The actual array that lines up the railway steps.
      # Gets converted into a Circuit/Activity via #to_activity.
      class Sequence < ::Array
        def alter!(options, *args)
          return insert(find_index(options[:before]),  [ *args, options ]) if options[:before]
          return insert(find_index(options[:after])+1, [ *args, options ]) if options[:after]
          return self[find_index(options[:replace])] = [ *args, options ]  if options[:replace]
          return delete_at(find_index(options[:delete])) if options[:delete]

          self << [ *args, options ]
        end

        # Transform array of steps into an Activity.
        def to_activity(activity)
          each do |(step, direction, connections, insert_before, options)|

            # insert the new step before the track's End, taking over all its incoming connections.
            activity = Circuit::Activity::Before(activity, insert_before, step, direction: direction, debug: {step => options[:name]}) # TODO: direction => outgoing

            # connect new task to End.left (if it's a step), or End.fail_fast, etc.
            connections.each do |(direction, target)|
              activity = Circuit::Activity::Connect(activity, step, direction, target)
            end
          end

          activity
        end

        private
        def find_index(name)
          row = find { |row| row.last[:name] == name }
          index(row)
        end
      end

      module End
        class Success < Circuit::End
        end
        class Failure < Circuit::End
        end
      end


      # Insert a step into the circuit.
      #:private:
      module Activity
        module_function
        # idea: those methods could live somewhere else.
        StepArgs = Struct.new(:original_options, :incoming_direction, :connections, :args_for_Step, :insert_before)

        # Helpers to create StepArgs{} for ::for.
        def args_for_pass(activity, *args); StepArgs.new( args, Circuit::Right, [],                                                   [Circuit::Right, Circuit::Right], activity[:End, :right] ); end
        def args_for_fail(activity, *args); StepArgs.new( args, Circuit::Left,  [],                                                   [Circuit::Left, Circuit::Left], activity[:End, :left] ); end
        def args_for_step(activity, *args); StepArgs.new( args, Circuit::Right, [[ Circuit::Left, activity[:End, :left] ]], [Circuit::Right, Circuit::Left], activity[:End, :right] ); end

        # @api private
        # 1. Processes the step API's options (such as `:override` of `:before`).
        # 2. Uses alter! =====> Railway
        # Returns an Activity instance.
        def for(railway, activity, step_config)
          proc, options = step_config.original_options

          _proc, _options = normalize_args(proc, options)
          options = _options.merge(options)
          options = options.merge(replace: options[:name]) if options[:override] # :override

          step    = Step(_proc, *step_config.args_for_Step)

          # insert Step into Sequence (append, replace, before, etc.)
          railway.alter!(options, step, step_config.incoming_direction, step_config.connections, step_config.insert_before)

          # convert Sequence to new Activity.
          railway.to_activity(activity)
        end

        # @api private
        # Decompose single array from macros or set default name for user step.
        def normalize_args(proc, options)
          proc.is_a?(Array) ?
            proc :                   # macro
            [ proc, { name: proc } ] # user step
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
      end
    end


    # Allows defining dependencies and inject/override them via runtime options, if desired.
    class Railway::Step
      def initialize(step, dependencies={})
        @step, @dependencies = step, dependencies
      end

      def call(input, options)
        @dependencies.each { |k, v| options[k] ||= v } # not sure i like this, but the step's API is cool.

        @step.(input, options)
      end
    end
  end
end
