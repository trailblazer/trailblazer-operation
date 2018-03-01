require "forwardable"

# trailblazer-context
require "trailblazer/option"
require "trailblazer/context"
require "trailblazer/container_chain"

require "trailblazer/activity"
require "trailblazer/activity/dsl/magnetic"


require "trailblazer/operation/variable_mapping"
require "trailblazer/operation/callable"

require "trailblazer/operation/heritage"
require "trailblazer/operation/public_call"      # TODO: Remove in 3.0.
require "trailblazer/operation/skill"
require "trailblazer/operation/deprecated_macro" # TODO: remove in 2.2.
require "trailblazer/operation/result"
require "trailblazer/operation/railway"

require "trailblazer/operation/railway/fast_track"
require "trailblazer/operation/railway/normalizer"
require "trailblazer/operation/trace"

require "trailblazer/operation/railway/macaroni"

module Trailblazer
  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, skills, etc.
  class Operation

    module FastTrackActivity
      builder_options = {
        track_end:     Railway::End::Success.new(semantic: :success),
        failure_end:   Railway::End::Failure.new(semantic: :failure),
        pass_fast_end: Railway::End::PassFast.new(semantic: :pass_fast),
        fail_fast_end: Railway::End::FailFast.new(semantic: :fail_fast),
      }

      extend Activity::FastTrack( pipeline: Railway::Normalizer::Pipeline, builder_options: builder_options )
    end

    extend Skill::Accessors        # ::[] and ::[]= # TODO: fade out this usage.

    def self.inherited(subclass)
      super
      subclass.initialize!
      heritage.(subclass)
    end

    def self.initialize!
      @activity = FastTrackActivity.clone
    end


    extend Activity::Interface

    module Process
      # Call the actual {Process} with the options prepared in PublicCall.
      #
      # @private
      def __call__(args, argumenter: [], **circuit_options)
        @activity.( args, circuit_options.merge(
            exec_context: new,
            argumenter:  argumenter + [ Activity::TaskWrap.method(:arguments_for_call) ], # FIXME: should we move this outside?
          )
        )
      end

      def to_h
        @activity.to_h.merge( activity: @activity )
      end
    end

    extend Process # make ::call etc. class methods on Operation.

    extend Heritage::Accessor

    class << self
      extend Forwardable # TODO: test those helpers
      def_delegators :@activity, :Path, :Output, :End, :Track
      def_delegators :@activity, :outputs, :debug

      def step(task, options={}, &block); add_task!(:step, task, options, &block) end
      def pass(task, options={}, &block); add_task!(:pass, task, options, &block) end
      def fail(task, options={}, &block); add_task!(:fail, task, options, &block) end

      alias_method :success, :pass
      alias_method :failure, :fail

      def add_task!(name, task, options, &block)
        heritage.record(name, task, options, &block)
        @activity.send(name, task, options, &block)
      end
    end

    extend PublicCall              # ::call(params, { current_user: .. })
    extend Trace                   # ::trace
  end
end

require "trailblazer/operation/inspect"
