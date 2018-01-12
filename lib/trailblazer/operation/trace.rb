module Trailblazer
  class Operation
    module Trace
      # @note The problem in this method is, we have redundancy with Operation::PublicCall
      def self.call(operation, *args)
        ctx = PublicCall.options_for_public_call(*args)   # redundant with PublicCall::call.

        # Prepare the tracing-specific arguments. This is only run once for the entire circuit!
        operation, (options, flow_options), circuit_options = Trailblazer::Activity::Trace.arguments_for_call( operation, [ctx, {}], {} )

        circuit_options = circuit_options.merge({ argumenter: [ Trailblazer::Activity::Introspect.method(:arguments_for_call) ] }) # this is called for every Activity.


        last_signal, (options, flow_options) =
          operation.__call__( # FIXME: this is the only problem.
            [options, flow_options],
            circuit_options
          )

        result = Railway::Result(last_signal, options)    # redundant with PublicCall::call.

        Result.new(result, flow_options[:stack].to_a)
      end

      # `Operation::trace` is included for simple tracing of the flow.
      # It simply forwards all arguments to `Trace.call`.
      #
      # @public
      #
      #   Operation.trace(params, "current_user" => current_user).wtf
      def trace(*args)
        Trace.(self, *args)
      end

      # Presentation of the traced stack via the returned result object.
      # This object is wrapped around the original result in {Trace.call}.
      class Result < SimpleDelegator
        def initialize(result, stack)
          super(result)
          @stack = stack
        end

        def wtf
          Trailblazer::Activity::Trace::Present.tree(@stack)
        end

        def wtf?
          puts wtf
        end
      end
    end
  end
end
