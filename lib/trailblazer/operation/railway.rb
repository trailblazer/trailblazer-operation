require "trailblazer/operation/result"
require "trailblazer/circuit"

module Trailblazer
  class Operation
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
          activity = self["pipetree"] # TODO: injectable? WTF? how cool is that?

          last, operation, flow_options = activity.(activity[:Start], options, context: new) # TODO: allow different context.

          # Result is successful if the activity ended with the "right" End event.
          Result.new(last == activity[:End, :right], options)
        end

        def initialize_railway!
          heritage.record :initialize_railway!
          self["railway"] = []
        end
      end

      # Transform railway array into an Activity.
      def self.to_activity(railway)
        activity = InitialActivity()

        railway.each do |(step, track, direction, connections)|
          # insert the new step before the track's End, taking over all its incoming connections.
          activity = Circuit::Activity::Before(activity, activity[:End, track], step, direction: direction) # TODO: direction => outgoing

          # connect new task to End.left (if it's a step), or End.fail_fast, etc.
          connections.each do |(direction, end_name)|
            activity = Circuit::Activity::Connect(activity, step, direction, activity[:End, end_name])
          end
        end

        activity
      end

      # The initial Activity with no-op wiring.
      def self.InitialActivity()
        Circuit::Activity({id: "A/"},
          end: {
            right:     Circuit::End.new(:right),
            left:      Circuit::End.new(:left),
            pass_fast: Circuit::End.new(:pass_fast),
            fail_fast: Circuit::End.new(:fail_fast)
          }
        ) do |evt|
          { evt[:Start] => { Circuit::Right => evt[:End, :right], Circuit::Left => evt[:End, :left] } }
        end
      end


      module DSL
        def success(*args); add(:right, Circuit::Right, [], *args) end
        def failure(*args); add(:left,  Circuit::Left,  [], *args) end
        def step(*args)   ; add(:right, Circuit::Right, [[Circuit::Left, :left]], *args) end

      private
        def add(track, incoming_direction, connections, proc, options={})
          heritage.record(:add, track, incoming_direction, proc, options)

          self["pipetree"] = DSL.insert(self["railway"], track, incoming_direction, connections, proc, options)
        end

        # :private:
        def self.insert(railway, track, direction, connections, proc, options={}) # TODO: make :name required arg.
          _proc, _options = normalize_args(proc, options)

          options = _options.merge(options)
          options = options.merge(replace: options[:name]) if options[:override] # :override

          step = connections.any? ?
            Step(_proc, Circuit::Right, Circuit::Left) : # if connections, this is usually #step.
            Step(_proc, direction, direction)            # or pass/fail

          railway << [ step, track, direction, connections, options ]

          Railway.to_activity(railway)
        end

        # Decompose single array from macros or set default name for user step.
        def self.normalize_args(proc, options)
          proc.is_a?(Array) ?
            proc :                   # macro
            [ proc, { name: proc } ] # user step
        end

        # Step calls step.(options, **options, flow_options)
        # Output direction binary: true=>Right, false=>Left.
        def self.Step(step, on_true, on_false)
          Circuit::Task::Binary(Circuit::Task::Args::KW(step), on_true, on_false)
        end
      end # DSL

      module_function
      def fail!     ; Circuit::Left  end
      def fail_fast!; FailFast       end
      def pass!     ; Circuit::Right end
      def pass_fast!; PassFast       end

      private
      FailFast = Class.new(Circuit::Left)
      PassFast = Class.new(Circuit::Right)
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
