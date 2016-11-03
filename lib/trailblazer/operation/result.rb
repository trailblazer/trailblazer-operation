class Trailblazer::Operation
  class Result
    def initialize(success, data)
      @success, @data = success, data
    end

    extend Uber::Delegates
    delegates :@data, :[]

    def success?
      @success
    end

    def failure?
      ! success?
    end

    # DISCUSS: the two methods below are more for testing.
    def inspect
      "<Result:#{success?} #{@data.inspect} >"
    end

    def slice(*keys)
      keys.collect { |k| self[k] }
    end
  end
end
