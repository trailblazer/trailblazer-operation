module Trailblazer
  class Operation
    module Railway
      def self.fail!     ; Activity::Left  end
      def self.pass!     ; Activity::Right end
      def self.fail_fast!; Activity::FastTrack::FailFast end
      def self.pass_fast!; Activity::FastTrack::PassFast end
    end # Railway
  end
end
