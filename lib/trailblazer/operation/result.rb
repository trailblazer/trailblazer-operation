class Trailblazer::Operation
  class Result
    # @param event The last emitted signal in a circuit is usually the end event.
    # @param data Context
    def initialize(event, data)
      @event, @data = event, data
    end

    attr_reader :event

    extend Forwardable
    def_delegators :@data, :[] # DISCUSS: make it a real delegator? see Nested.

    # DISCUSS: the two methods below are more for testing.
    def inspect(*slices)
      return "<Result:#{success?} #{slice(*slices).inspect} >" if slices.any?
      "<Result:#{success?} #{@data.inspect} >"
    end

    def slice(*keys)
      keys.collect { |k| self[k] }
    end
  end
end
