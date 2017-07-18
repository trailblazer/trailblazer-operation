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
        # @param start_at [Object] the task where to start circuit.
        # @param options [Hash, Skill] options to be passed to the first task
        # @param flow_options [Hash] arbitrary flow control options.
        # @return direction, options, flow_options
        def __call__(start_at, options, flow_options)
          # add the local operation's class dependencies to the skills.
          options = Trailblazer::Skill.new(options, self.skills)

          self["__activity__"].(start_at, options, flow_options.merge( exec_context: new ))
        end

        # This method gets overridden by PublicCall#call which will provide the Skills object.
        # @param options [Skill,Hash] all dependencies and runtime-data for this call
        # @return see #__call__
        def call(options)
          __call__( self["__activity__"][:Start], options, {} )
        end

        def initialize_activity!
          heritage.record :initialize_activity!

          self["__sequence__"]  = Sequence.new
          self["__activity__"] = InitialActivity()

          self["__activity_alterations__"] = DSL::Alterations.new # mutable DSL object.
          self["__activity_alterations__"] << ->(*) { InitialActivity() }
        end

        private
        # The initial {Activity} circuit with no-op wiring.
        def InitialActivity
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
            result = Trailblazer::Option::KW(step).(options, **flow_options)

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
