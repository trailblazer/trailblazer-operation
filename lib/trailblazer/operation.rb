module Trailblazer
  class Operation
    VERSION = "1.2.0"

    class << self
      def call(*args)
        # TODO: builder!
        new(*args).call
      end
    end

    def initialize(**args)

    end

    def call(*)
      self
    end
  end
end
