module Trailblazer
  module Operation::Railway
    def self.fail!     ; Circuit::Left  end
    def self.fail_fast!; FailFast       end
    def self.pass!     ; Circuit::Right end
    def self.pass_fast!; PassFast       end

    # Direction signals.
    class FailFast < Circuit::Left;  end
    class PassFast < Circuit::Right; end

    module End
      FailFast = Class.new(Operation::Railway::End::Failure).new(:fail_fast)
      PassFast = Class.new(Operation::Railway::End::Success).new(:pass_fast)
    end
  end
end
