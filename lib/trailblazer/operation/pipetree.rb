require "pipetree"
require "pipetree/railway"
require "trailblazer/operation/result"

require "trailblazer/circuit"

if RUBY_VERSION == "1.9.3"
  require "trailblazer/operation/1.9.3/option" # TODO: rename to something better.
else
  require "trailblazer/operation/option" # TODO: rename to something better.
end

module Trailblazer
  class Operation
    # Instantiate = ->(klass, options, flow_options) { klass.new(options) } # returns operation instance.

    # Implements the API to populate the operation's pipetree and
    # `Operation::call` to invoke the latter.
    # Learn more about the Pipetree gem here: https://github.com/apotonick/pipetree
    module Pipetree
      def self.included(includer)
        includer.extend ClassMethods # ::call, ::inititalize_pipetree!
        includer.extend DSL          # ::|, ::> and friends.

        includer.initialize_pipetree!
      end

      module ClassMethods
        # Top-level, this method is called when you do Create.() and where
        # all the fun starts, ends, and hopefully starts again.
        def call(options)
          activity = self["pipetree"] # TODO: injectable? WTF? how cool is that?

          circuit, _ = activity.values
          require "pp"
          pp circuit
          # puts "@@@@@ #{circuit.inspect}"

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

      class Railway < ::Pipetree::Railway
        FailFast = Class.new(Left)
        PassFast = Class.new(Right)

        def self.fail!     ; Left     end
        def self.fail_fast!; FailFast end
        def self.pass!     ; Right    end
        def self.pass_fast!; PassFast end
      end



      module DSL
        def success(*args); add(:right, Circuit::Right, [], *args) end
        def failure(*args); add(:left,  Circuit::Left,  [], *args) end
        def step(*args)   ; add(:right, Circuit::Right, [[Circuit::Left, :left]], *args) end

      private
        # call the step proc with (options, flow_options), omitting `direction`.
        def self.Step(step)
          ->(direction, options, flow_options) do
            result = step.(options, flow_options)

            [ result ? Circuit::Right : Circuit::Left, options, flow_options ]
          end
        end

        def self.Stay(step, direction)
          ->(direction, options, flow_options) do
            result = step.(options, flow_options)

            [ direction, options, flow_options ]
          end
        end

        # Operation-level entry point.
        def add(track, decider_class, connections, proc, options={})
          heritage.record(:add, track, decider_class, proc, options)

          self["pipetree"] = DSL.insert(self["___railway"], track, decider_class, connections, proc, options)
        end

        def self.insert(railway, track, direction, connections, proc, options={}) # TODO: make :name required arg.
          _proc, options = proc.is_a?(Array) ? macro!(proc, options) : step!(proc, options)

          options = options.merge(replace: options[:name]) if options[:override] # :override

          # TODO: what about left track?
          step = connections.any? ? Step(_proc) : Stay(_proc, direction)

          # connections = [[Circuit::Left, :left]]
          railway << [ step, track, direction, connections ]

          Pipetree.to_activity(railway)
        end

        def self.macro!(proc, options)
          _proc, macro_options = proc

          [ _proc, macro_options.merge(options) ]
        end

        def self.step!(proc, options)
          name  = ""
          _proc = Option::KW.(proc) do |type|
            name = proc if type == :symbol
            name = "#{proc.source_location[0].split("/").last}:#{proc.source_location.last}" if proc.is_a? Proc if type == :proc
            name = proc.class  if type == :callable
          end

          [ _proc, { name: name }.merge(options) ]
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
