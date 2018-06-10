module Trailblazer
  module Operation::Railway
    # rubocop:disable Layout/EmptyLineBetweenDefs,Layout/SpaceBeforeSemicolon
    def self.fail!     ; Activity::Left  end
    def self.pass!     ; Activity::Right end
    def self.fail_fast!; Activity::FastTrack::FailFast end
    def self.pass_fast!; Activity::FastTrack::PassFast end
    # rubocop:enable Layout/EmptyLineBetweenDefs,Layout/SpaceBeforeSemicolon

    module End
      FailFast = Class.new(Operation::Railway::End::Failure)
      PassFast = Class.new(Operation::Railway::End::Success)
    end
  end
end
