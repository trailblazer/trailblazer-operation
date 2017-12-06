module Trailblazer
  # Operations is simply a thin API to define, inherit and run circuits by passing the options object.
  # It encourages the linear railway style (http://trb.to/gems/workflow/circuit.html#operation) but can
  # easily be extend for more complex workflows.
  class Operation
    # End event: All subclasses of End:::Success are interpreted as "success".
    module Railway
      # @param options Context
      # @param end_event The last emitted signal in a circuit is usually the end event.
      def self.Result(end_event, options, *)
        Result.new(end_event.kind_of?(End::Success), options, end_event)
      end

      # The Railway::Result knows about its binary state, the context (data), and the last event in the circuit.
      class Result < Result # Operation::Result
        def initialize(success, data, event)
          super(success, data)

          @event = event
        end

        attr_reader :event
      end

      module End
        class Success < Activity::End; end
        class Failure < Activity::End; end
      end

    end # Railway
  end
end
