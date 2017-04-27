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

          self["__sequence__"]  = Sequence.new
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

      module End
        class Success < Circuit::End; end
        class Failure < Circuit::End; end
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

require "trailblazer/operation/dsl"
require "trailblazer/operation/activity"
require "trailblazer/operation/sequence"
