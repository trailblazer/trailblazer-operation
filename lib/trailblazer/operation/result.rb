module Trailblazer
  class Operation
    class Result
      def self.build(signal, ctx)
        new(signal.kind_of?(Activity::Terminus::Success), ctx, signal)
      end

      def initialize(success, data, signal)
        @success, @data, @signal = success, data, signal
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
end
