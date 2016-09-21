module Trailblazer
  class Operation
    VERSION = "1.2.0"

    class << self
      def call(**args)
        # TODO: builder!
        new(**args).result(args[:params] || {})
      end
    end

    def initialize(**args)

    end

    def result(**) # receives args[:params]
      call#(*)
      self
    end

    def call(**)
    end
  end
end
