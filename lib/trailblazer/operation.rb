module Trailblazer
  class Operation
    VERSION = "1.2.0"

    class << self
      def call(**args)
        # TODO: builder!
        new(**args).call(args[:params] || {})
      end
    end

    def initialize(**args)
      @valid = true
    end

    def call(**) # receives args[:params]
      result(process)#(*)
    end

  private
    def process(**)
    end

    # Compute the result object.
    def result(returned, **)
      { valid: @valid, operation: self }#.merge(returned)
    end
  end
end

# initialize: @result = {}
# call -> merge .process
