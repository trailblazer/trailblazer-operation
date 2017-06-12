module Trailblazer
  class Operation
    module Trace
      def self.call(operation, *args)
        skill  = Operation::Skill(operation, *args)

        # let Circuit::Trace::call handle all parameters, just make sure it calls Operation.__call__
        stack, direction, options, flow_options = Circuit::Trace.(operation, operation["__activity__"][:Start], skill) { |operation, *args| operation.__call__(*args) }

        result = Railway::Result(direction, options)

        Result.new(result, stack)
      end

      # @public
      #   Operation.trace(params, "current_user" => current_user).wtf
      def trace(params, options={}, *dependencies)
        Trace.(self, params, options, *dependencies)
      end

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
