class Trailblazer::Operation
  class Result
    # @param success Boolean validity of the result object
    # @param data Context
    def initialize(success, data)
      @success, @data = success, data
    end

    def success?
      @success
    end

    def failure?
      !success?
    end

    def to_hash
      data.to_hash
    end

    def keys
      data.to_hash.keys
    end

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

    private

    attr_reader :data
  end
end
