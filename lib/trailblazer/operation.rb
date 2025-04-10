require "trailblazer/operation/version"
require "trailblazer/activity/dsl/linear"
require "trailblazer/invoke"
require "forwardable"

#
# Developer's docs: https://trailblazer.to/2.1/docs/internals.html#internals-operation
#
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

  def self.Operation(options)
    Class.new(Activity::FastTrack( Activity::Operation.OptionsForState.merge(options) )) do
      extend Operation::PublicCall
      raise # FIXME: what is the matter with you?
    end
  end

  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, etc.
  class Operation < Activity::FastTrack(**Activity::Operation.OptionsForState)
    class << self
      alias_method :strategy_call, :call
    end

    def self.configure!(&block)
      Trailblazer::Invoke.module!(self.singleton_class, &block) # => Operation.__() as a canonical invoke.
      self
    end

    require "trailblazer/operation/public_call"
    extend PublicCall # Operation.call that exposes a switch for two different interfaces.

    require "trailblazer/operation/wtf"
    extend Wtf                   # Operation.trace
  end
end

require "trailblazer/operation/result"
require "trailblazer/operation/railway"

Trailblazer::Operation.configure! { {} } # create a default Operation.() with no dynamic args set.

# FIXME: move this to Activity and add inheritance etc.
Trailblazer::Operation.instance_variable_get(:@state).update!(:fields) do |fields|
  # Override Activity's initial taskWrap.
  fields.merge(
    task_wrap: Trailblazer::Operation::PublicCall::INITIAL_TASK_WRAP  # HERE, we can add other tw steps like dependeny injection.
  )
end
