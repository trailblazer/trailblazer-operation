class Trailblazer::Operation
  class Result
    def initialize(success, data)
      @success, @data = success, data # @data is a Skill instance.
    end

    extend Forwardable
    def_delegators :@data, :[] # DISCUSS: make it a real delegator? see Nested.

    def success?
      @success
    end

    def failure?
      ! success?
    end

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
