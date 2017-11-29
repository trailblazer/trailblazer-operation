module Trailblazer
  module Operation::Railway
    module FastTrack

      def fail!     ; Circuit::Left  end
      def fail_fast!; FailFast       end
      def pass!     ; Circuit::Right end
      def pass_fast!; PassFast       end

      private

      # Direction signals.
      class FailFast < Circuit::Left;  end
      class PassFast < Circuit::Right; end

      module End
        FailFast = Class.new(Operation::Railway::End::Failure).new(:fail_fast)
        PassFast = Class.new(Operation::Railway::End::Success).new(:pass_fast)
      end
    end
  end
end
