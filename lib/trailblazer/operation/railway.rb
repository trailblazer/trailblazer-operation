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

        includer.initialize_railway!
      end

      module ClassMethods
        # Top-level, this method is called when you do Create.() and where
        # all the fun starts, ends, and hopefully starts again.
        def call(options)
          activity = self["pipetree"] # FIXME: rename to activity, deprecate ["pipetree"].inspect

          last, operation, flow_options = activity.(activity[:Start], options, context: new) # TODO: allow different context.

          # Result is successful if the activity ended with the "right" End event.
          Result.new(last.kind_of?(End::Success), options)
        end

        def initialize_railway!
          heritage.record :initialize_railway!
          self["railway"] = Sequence.new
          self["railway_extra_events"]  = {}
        end
      end

      # Data object: The actual array that lines up the railway steps.
      # Gets converted into a Circuit/Activity via #to_activity.
      class Sequence < ::Array
        def alter!(step, track, direction, connections, options)
          return insert(find_index(options[:before]),  [ step, track, direction, connections, options ]) if options[:before]
          return insert(find_index(options[:after])+1, [ step, track, direction, connections, options ]) if options[:after]
          return self[find_index(options[:replace])] = [ step, track, direction, connections, options ]  if options[:replace]
          return delete_at(find_index(options[:delete]))                                                 if options[:delete]

          self << [ step, track, direction, connections, options ]
        end

        # Transform railway array into an Activity.
        def to_activity(events)
          step2name = collect { |cfg| [cfg.first, cfg.last[:name]] }.to_h # debug argument for Activity.
          activity  = InitialActivity(events, step2name)

          each do |(step, track, direction, connections, options)|

            # insert the new step before the track's End, taking over all its incoming connections.
            activity = Circuit::Activity::Before(activity, activity[:End, track], step, direction: direction) # TODO: direction => outgoing

            # connect new task to End.left (if it's a step), or End.fail_fast, etc.
            connections.each do |(direction, end_name)|
              activity = Circuit::Activity::Connect(activity, step, direction, activity[:End, end_name])
            end
          end

          activity
        end

        private
        def find_index(name)
          row = find { |row| row.last[:name] == name }
          index(row)
        end

        # The initial Activity with no-op wiring.
        def InitialActivity(events, debug)
          default_ends = {
            right: End::Success.new(:right),
            left:  Circuit::End.new(:left)
          }

          Circuit::Activity(debug, end: default_ends.merge(events)) do |evt|
            { evt[:Start] => { Circuit::Right => evt[:End, :right], Circuit::Left => evt[:End, :left] } }
          end
        end
      end

      module End
        class Success < Circuit::End
        end
      end

      # This is code run at compile-time and can be slow.
      module DSL
        def success(*args); add( *args_for_pass(*args) ); end
        def failure(*args); add( *args_for_fail(*args) ); end
        def step(*args)   ; add( *args_for_step(*args) ); end

        def args_for_pass(*args); [ :right, Circuit::Right, [], [Circuit::Right, Circuit::Right], *args ]; end
        def args_for_fail(*args); [ :left, Circuit::Left,   [], [Circuit::Left, Circuit::Left],   *args ]; end
        def args_for_step(*args); [ :right, Circuit::Right, [[Circuit::Left, :left]], [Circuit::Right, Circuit::Left], *args ]; end

      private
        def add(track, incoming_direction, connections, step_args, proc, options={})
          heritage.record(:add, track, incoming_direction, connections, step_args, proc, options)

          self["pipetree"] = Alter.insert(self["railway"], self["railway_extra_events"], track, incoming_direction, connections, step_args, proc, options)
        end
      end # DSL

      # Insert a step into the circuit.
      #:private:
      module Alter
      module_function
        # :private:
        # 1. Processes the step API's options (such as `:override` of `:before`).
        # 2. Uses alter! =====> Railway
        # Returns an Activity instance.
        def insert(railway, events, track, direction, connections, step_args, proc, options={})
          _proc, _options = normalize_args(proc, options)

          options = _options.merge(options)
          options = options.merge(replace: options[:name]) if options[:override] # :override

          step    = Step(_proc, *step_args)

          railway.alter!(step, track, direction, connections, options) # append, replace, before, etc.

          railway.to_activity(events)
        end

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
