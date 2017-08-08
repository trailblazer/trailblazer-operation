module Trailblazer
  class Operation
    module Trace
      def self.call(operation, *args)
        # let Circuit::Trace::call handle all parameters, just make sure it calls Operation.__call__
        call_block = ->(operation, *args) { operation.__call__(*args) }

        stack, direction, options, flow_options = Circuit::Trace.(
          operation,
          operation.instance_variable_get(:@start),
          *args,
          &call_block # instructs Trace to use __call__.
        )

        result = Railway::Result(direction, options)

        Result.new(result, stack)
      end

      # `Operation::trace` is included for simple tracing of the flow.
      # It simply forwards all arguments to `Trace.call`.
      #
      # @public
      #
      #   Operation.trace(params, "current_user" => current_user).wtf
      def trace(params, options={}, *dependencies)
        Trace.(self, params, options, *dependencies)
      end

      # Presentation of the traced stack via the returned result object.
      # This object is wrapped around the original result in {Trace.call}.
      class Result < SimpleDelegator
        def initialize(result, stack)
          super(result)
          @stack = stack
        end

        def wtf?
          Circuit::Trace::Present.tree(@stack)
        end

        def wtf
          puts wtf?
        end
      end
    end
  end
end
