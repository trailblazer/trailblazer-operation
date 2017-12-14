require "forwardable"

# trailblazer-context
require "trailblazer/option"
require "trailblazer/context"
require "trailblazer/container_chain"

require "trailblazer/activity"
require "trailblazer/activity/magnetic"
require "trailblazer/activity/wrap"

require "trailblazer/operation/variable_mapping"

require "trailblazer/operation/public_call"      # TODO: Remove in 3.0.
require "trailblazer/operation/skill"
require "trailblazer/operation/deprecated_macro" # TODO: remove in 2.2.
require "trailblazer/operation/result"
require "trailblazer/operation/railway"

require "trailblazer/operation/railway/task_builder"
require "trailblazer/operation/railway/fast_track"
require "trailblazer/operation/railway/normalizer"
require "trailblazer/operation/task_wrap"
require "trailblazer/operation/trace"

module Trailblazer
  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, skills, etc.
  class Operation
    extend Skill::Accessors        # ::[] and ::[]= # TODO: fade out this usage.

    def self.inherited(subclass)
      super
      subclass.initialize!
      heritage.(subclass)
    end

    module Process
      def initialize!
        initialize_activity_dsl!
        recompile_process!
      end

      # builder is stateless, it's up to you to save @adds somewhere.
      def initialize_activity_dsl!
        builder_options = {
          track_end:     Railway::End::Success.new(:success, semantic: :success),
          failure_end:   Railway::End::Failure.new(:failure, semantic: :failure),
          pass_fast_end: Railway::End::PassFast.new(:pass_fast, semantic: :pass_fast),
          fail_fast_end: Railway::End::FailFast.new(:fail_fast, semantic: :fail_fast),
        }

        @builder, @adds = Activity::Magnetic::Builder::FastTrack.for( Railway::Normalizer, builder_options )
        @debug          = {}
      end

      def recompile_process!
        @process, @outputs = Activity::Recompile.( @adds )
      end

      def outputs
        @outputs
      end

      include Activity::Interface

      # Call the actual {Process} with the options prepared in PublicCall.
      def __call__(args, circuit_options={})
        @process.( args, circuit_options.merge( exec_context: new ) )
      end
    end

    extend Process # make ::call etc. class methods on Operation.

    extend Activity::Heritage::Accessor

    extend Activity::DSL # #_task
    # delegate step, pass and fail via Operation::_task to the @builder, and save results in @adds.
    extend Activity::DSL.def_dsl! :step
    extend Activity::DSL.def_dsl! :pass
    extend Activity::DSL.def_dsl! :fail
    class << self
      alias_method :success, :pass
      alias_method :failure, :fail

      extend Forwardable # TODO: test those helpers
      def_delegators :@builder, :Path, :Output, :End #, :task
    end

    extend PublicCall              # ::call(params, { current_user: .. })
    extend Trace                   # ::trace


    include Railway::TaskWrap
  end
end

require "trailblazer/operation/inspect"
