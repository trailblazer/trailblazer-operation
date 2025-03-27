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

    extend Forwardable
    def_delegators :@data, :[], :to_h, :keys # DISCUSS: make it a real delegator? see Nested.
  end
end
