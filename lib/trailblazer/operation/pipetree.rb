require "trailblazer/operation/result"
require "trailblazer/circuit"
require "trailblazer/operation/option"

module Trailblazer
  class Operation
    module Pipetree
      def self.included(includer)
        includer.extend ClassMethods # ::call, ::inititalize_pipetree!
        includer.extend DSL

        includer.initialize_pipetree!
      end

      module ClassMethods
        # Top-level, this method is called when you do Create.() and where
        # all the fun starts, ends, and hopefully starts again.
        def call(options)
          activity = self["pipetree"] # TODO: injectable? WTF? how cool is that?

          circuit, _ = activity.values
          # require "pp"
          # pp circuit

          last, operation, flow_options = activity.(activity[:Start], options, context: new)

          # Result is successful if the activity ended with the "right" End event.
          Result.new(last == activity[:End, :right], options)
        end

        # This method would be redundant if Ruby had a Class::finalize! method the way
        # Dry.RB provides it. It has to be executed with every subclassing.
        def initialize_pipetree!
          heritage.record :initialize_pipetree!

          self["___railway"] = []
        end
      end

      # Transform railway array into an Activity.
      def self.to_activity(railway)
        activity = initial_activity

        railway.each do |(step, track, direction, connections)|
          # insert the new step before the track's End, taking over all its incoming connections.
          activity = Circuit::Activity::Alter(activity, :before, activity[:End, track], step, direction: direction) # TODO: direction => outgoing

          # connect new task to End.left (if it's a step), or End.fail_fast, etc.
          connections.each do |(direction, end_name)|
            activity = Circuit::Activity::Connect(activity, step, direction, activity[:End, end_name])
          end
        end

        activity
      end

      # The initial Activity with no-op wiring.
      def self.initial_activity()
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

      module Railway
        module_function
          def fail!     ; Circuit::Left  end
          def fail_fast!; FailFast       end
          def pass!     ; Circuit::Right end
          def pass_fast!; PassFast       end

        private
          FailFast = Class.new(Circuit::Left)
          PassFast = Class.new(Circuit::Right)
      end

      module DSL
        def success(*args); add(:right, Circuit::Right, [], *args) end
        def failure(*args); add(:left,  Circuit::Left,  [], *args) end
        def step(*args)   ; add(:right, Circuit::Right, [[Circuit::Left, :left]], *args) end

      private
        def add(track, decider_class, connections, proc, options={})
          heritage.record(:add, track, decider_class, proc, options)

          self["pipetree"] = DSL.insert(self["___railway"], track, decider_class, connections, proc, options)
        end

        def self.insert(railway, track, direction, connections, proc, options={}) # TODO: make :name required arg.
          _proc, options = proc.is_a?(Array) ? macro!(proc, options) : step!(proc, options)

          options = options.merge(replace: options[:name]) if options[:override] # :override

          step = connections.any? ? Step(_proc, Circuit::Right, Circuit::Left) : Step(_proc, direction, direction)

          railway << [ step, track, direction, connections ] # connections = [[Circuit::Left, :left]]

          Pipetree.to_activity(railway)
        end

        def self.macro!(proc, options)
          _proc, macro_options = proc

          [ _proc, macro_options.merge(options) ]
        end

        def self.step!(proc, options)
          [ Option::KW(proc), { name: proc }.merge(options) ]
        end

        # Returns task to call the step proc with (options, flow_options), omitting `direction`.
        # When called, the task always returns a direction signal.
        def self.Step(step, on_true, on_false)
          ->(direction, options, flow_options) do
            result = step.(options, flow_options)

            [ result ? on_true : on_false, options, flow_options ]
          end
        end
      end # DSL
    end

    # Allows defining dependencies and inject/override them via runtime options, if desired.
    class Pipetree::Step
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
