module Trailblazer
  class Operation
    class Result < Struct.new(:ctx, :signal)
      def self.build(signal, ctx)
        new(signal.kind_of?(Activity::Terminus::Success), ctx, signal)
      end

      def initialize(success, ctx, signal)
        @success = success
        super(ctx, signal)
      end

      def success?
        @success
      end

      def failure?
        !success?
      end

      alias_method :terminus, :signal

      extend Forwardable
      def_delegators :ctx, :[], :to_h, :keys # DISCUSS: make it a real delegator? see Nested.
    end
  end
end
