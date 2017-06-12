module Trailblazer
  # Operations is simply a thin API to define, inherit and run circuits by passing the options object.
  # It encourages the linear railway style (http://trb.to/gems/workflow/circuit.html#operation) but can
  # easily be extend for more complex workflows.

      # FIXME: rename pipetree, deprecate ["__pipetree__"].inspect
  class Operation
    # End event: All subclasses of End:::Success are interpreted as "success"?
    module Railway
      def self.included(includer)
        includer.extend ClassMethods # ::call, ::inititalize_pipetree!
        includer.extend DSL
        includer.extend DSL::DeprecatedMacro # TODO: remove in 2.2.

        includer.initialize_activity!
      end

      module ClassMethods
        # Low-level `Activity` call interface. Runs the circuit.
        #
        # @params start_at [Object] the task where to start circuit.
        # @params options [Hash, Skill] options to be passed around. Note that these need to be a `Skill` hash if you want that.
        # @params flow_options [Hash] arbitrary flow control options.
        # @returns direction, options, flow_options
        def __call__(start_at, options, flow_options)
          self["__activity__"].(start_at, options, flow_options.merge( exec_context: new ))
        end

        # Top-level operation call interface. It's called when you run Create.() and where
        # all the fun starts, ends, and hopefully starts again.
        def call(options)
          direction, options, _ = __call__( self["__activity__"][:Start], options, {} )

          # Result is successful if the activity ended with the "right" End event.
          Railway::Result(direction, options)
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
      end

      # The result of a railway is binary.
      def self.Result(direction, options)
        Result.new(direction.kind_of?(End::Success), options)
      end

      module End
        class Success < Circuit::End; end
        class Failure < Circuit::End; end
      end

      # every step is wrapped by this proc/decider. this is executed in the circuit as the actual task.
      # Step calls step.(options, **options, flow_options)
      # Output direction binary: true=>Right, false=>Left.
      # Passes through all subclasses of Direction.~~~~~~~~~~~~~~~~~
      module TaskBuilder
        def self.call(step, on_true=Circuit::Right, on_false=Circuit::Left)
          ->(direction, options, flow_options) do
            # Execute the user step with TRB's kw args.
            result = Circuit::Task::Args::KW(step).(direction, options, flow_options)

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
end
