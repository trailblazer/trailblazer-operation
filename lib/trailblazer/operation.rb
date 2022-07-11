require "trailblazer/activity/dsl/linear"
require 'forwardable'
require 'trailblazer/operation/version'

module Trailblazer
  # As opposed to {Activity::Railway} and {Activity::FastTrack} an operation
  # maintains different terminus subclasses.
  # DISCUSS: remove this, at some point in time!
  class Activity
    class Railway
      module End
        # @private
        class Success < Activity::End; end
        class Failure < Activity::End; end

        class FailFast < Failure; end
        class PassFast < Success; end
      end
    end

    module Operation
      def self.OptionsForState()
        {
          end_task:      Activity::Railway::End::Success.new(semantic: :success),
          failure_end:   Activity::Railway::End::Failure.new(semantic: :failure),
          fail_fast_end: Activity::Railway::End::FailFast.new(semantic: :fail_fast),
          pass_fast_end: Activity::Railway::End::PassFast.new(semantic: :pass_fast),
        }
      end
    end
  end

  # DISCUSS: where do we need this?
  def self.Operation(options)
    Class.new(Activity::FastTrack( Activity::Operation.OptionsForState.merge(options) )) do
      extend Operation::PublicCall
    end
  end

  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, etc.
  class Operation < Activity::FastTrack(**Activity::Operation.OptionsForState)
    # include Activity::DSL::Linear::Helper

    class << self
      alias_method :strategy_call, :call
    end

    require "trailblazer/operation/public_call"      # TODO: Remove in 3.0.
    extend PublicCall              # ::call(params: .., current_user: ..)

    require "trailblazer/operation/trace"
    extend Trace                   # ::trace
  end
end

require "trailblazer/operation/class_dependencies"
require "trailblazer/operation/deprecated_macro" # TODO: remove in 2.2.

require "trailblazer/operation/result"
require "trailblazer/operation/railway"

require "trailblazer/operation/railway/macaroni"
