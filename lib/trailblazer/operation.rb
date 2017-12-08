require "forwardable"
require "declarative"

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
    # support for declarative inheriting (e.g. the circuit).
    extend Declarative::Heritage::Inherited
    extend Declarative::Heritage::DSL

    extend Skill::Accessors        # ::[] and ::[]= # TODO: fade out this usage.
    # we want the skill dependency-mechanism.
    # extend Skill::Call             # ::call(params: .., current_user: ..)

    module Process
      def initialize_builder!
        heritage.record :initialize_builder!

        initialize_activity_dsl!
        recompile_process!
      end

      def initialize_activity_dsl!
        builder_options = {
          track_end:     Railway::End::Success.new(:success, semantic: :success),
          failure_end:   Railway::End::Failure.new(:failure, semantic: :failure),
          pass_fast_end: Railway::End::PassFast.new(:pass_fast, semantic: :pass_fast),
          fail_fast_end: Railway::End::FailFast.new(:fail_fast, semantic: :fail_fast),
        }

        @builder = Activity::Magnetic::Builder::FastTrack.new( Railway::Normalizer, builder_options )
        @debug = {}
      end

      def recompile_process!
        @process, @outputs = Activity::Recompile.( @builder )
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

    # DSL part
    # delegate as much as possible to Builder
    module DSL
      extend Forwardable
      def_delegators :@builder, :Output, :Path

      def step(*args, &block)
        _element(:step, *args, &block)
      end

      def pass(*args, &block)
        _element(:pass, *args, &block)
      end

      def fail(*args, &block)
        _element(:fail, *args, &block)
      end

      alias_method :success, :pass
      alias_method :failure, :fail

      # @private
      #
      # This method might be removed in favor for a better DSL hooks mechanism.
      def _element(type, *args, &block)
        heritage.record(type, *args, &block)

# TODO: merge with Activity
        adds, *options = @builder.send(type, *args, &block) # e.g. @builder.step
        recompile_process!
        add_introspection!(adds, *options)
        return adds, *options
      end

             def add_introspection!(adds, task, local_options, *)
        @debug[task] = { id: local_options[:id] }.freeze
      end
    end

    extend Process # make ::call etc. class methods on Operation.

    extend PublicCall              # ::call(params, { current_user: .. })
    extend Trace                   # ::trace

    extend DSL

    include Railway::TaskWrap

    initialize_builder!
  end
end

require "trailblazer/operation/inspect"
