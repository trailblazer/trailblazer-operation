require "delegate"
require "trailblazer/developer"

module Trailblazer
  class Operation
    module Trace
      # @note The problem in this method is, we have redundancy with Operation::PublicCall
      def self.call(operation, options)
        # warn %{Trailblazer: `Operation.trace` is deprecated. Please use `Operation.wtf?`.} # DISCUSS: should this be deprecated?
        ctx = PublicCall.options_for_public_call(options) # redundant with PublicCall::call.

        stack, signal, (ctx, _flow_options) = Developer::Trace.(operation, [ctx, {}])

        result = Railway::Result(signal, ctx) # redundant with PublicCall::call.

        Result.new(result, stack)
      end

      # `Operation::trace` is included for simple tracing of the flow.
      # It simply forwards all arguments to `Trace.call`.
      #
      # @public
      #
      #   Operation.trace(params, current_user: current_user).wtf
      # TODO: remove in 0.11.0.
      def trace(options)
        Activity::Deprecate.warn Trace.find_caller_location_for_deprecated, %(Using `Operation.trace` is deprecated and will be removed in {trailblazer-operation-0.11.0}.
  Please use `#{self}.wtf?` as documented here: https://trailblazer.to/2.1/docs/trailblazer#trailblazer-developer-wtf-)

        Trace.(self, options)
      end

      def wtf?(options)
        call_with_public_interface(options, {}, invoke_class: Developer::Wtf)
      end

      # TODO: remove in 0.11.0.
      def self.find_caller_location_for_deprecated
        our_caller_locations = caller_locations.to_a
        caller_location = our_caller_locations.reverse.find { |line| line.to_s =~ /operation\/trace/ }

        _caller_location = our_caller_locations[our_caller_locations.index(caller_location)+1]
      end

      # Presentation of the traced stack via the returned result object.
      # This object is wrapped around the original result in {Trace.call}.
      class Result < ::SimpleDelegator
        def initialize(result, stack)
          super(result)
          @stack = stack
        end

        # TODO: remove in 0.11.0.
        def wtf
          Activity::Deprecate.warn Trace.find_caller_location_for_deprecated, %(Using `result.wtf?` is deprecated. Please use `#{@stack.to_a[0].task}.wtf?` and have a nice day.)

          Developer::Trace::Present.(@stack)
        end

        # TODO: remove in 0.11.0.
        def wtf?
          puts wtf
        end
      end
    end
  end
end
