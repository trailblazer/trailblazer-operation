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
        def initialize_activity! # TODO: rename to circuit, or make it Activity?
          heritage.record :initialize_activity!

          self["__wirings__"] = []
          self["__wirings__"] += initial_activity

          self["__sequence__"] = Sequence.new # the `Sequence` instance is the only mutable/persisted object in this class.


          # FIXME: we only need to do this to support empty NOOPs.
          self["__activity__"] = recompile_activity( initial_activity ) # almost empty NOOP circuit.
        end

        # Low-level `Activity` call interface. Runs the circuit.
        #
        # @param start_at [Object] the task where to start circuit.
        # @param options [Hash, Skill] options to be passed to the first task. These are usually the "runtime options".
        # @param flow_options [Hash] arbitrary flow control options.
        # @return direction, options, flow_options
        def __call__(start_at, options, flow_options)
          # add the local operation's class dependencies to the skills.
          immutable_options = Trailblazer::Context::ContainerChain.new([options, self.skills])

          ctx = Trailblazer::Context(immutable_options)

          self["__activity__"].(start_at, ctx, flow_options.merge( exec_context: new ))
        end

        # This method gets overridden by PublicCall#call which will provide the Skills object.
        # @param options [Skill,Hash] all dependencies and runtime-data for this call
        # @return see #__call__
        def call(options)
          __call__( nil, options, {} )
        end

        private

        def initial_activity
          end_for_success = End::Success.new(:success)
          end_for_failure = End::Failure.new(:failure)

          [
            [ :attach!, target: [ end_for_success, type: :event, id: [:End, :success] ], edge: [ Circuit::Right, type: :railway ] ],
            [ :attach!, target: [ end_for_failure, type: :event, id: [:End, :failure] ], edge: [ Circuit::Left, type: :railway ] ],
          ]
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

    end # Railway
  end
end
