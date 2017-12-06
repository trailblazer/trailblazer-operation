require "forwardable"
require "declarative"

require "trailblazer/activity"
require "trailblazer/activity/magnetic"
require "trailblazer/activity/wrap"

require "trailblazer/operation/public_call"      # TODO: Remove in 3.0.
require "trailblazer/operation/skill"
require "trailblazer/operation/deprecated_macro" # TODO: remove in 2.2.
require "trailblazer/operation/result"
require "trailblazer/operation/railway"

require "trailblazer/operation/railway/task_builder"
require "trailblazer/operation/railway/fast_track"
require "trailblazer/operation/task_wrap"
require "trailblazer/operation/trace"

module Trailblazer
  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, skills, etc.
  class Operation
    # support for declarative inheriting (e.g. the circuit).
    extend Declarative::Heritage::Inherited
    extend Declarative::Heritage::DSL

    extend Skill::Accessors        # ::[] and ::[]=

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

        @builder = Activity::Magnetic::Builder::FastTrack.new( Normalizer, builder_options )
      end

      def recompile_process!
        @process, @outputs = Activity::Magnetic::Builder::FastTrack.finalize( @builder.instance_variable_get(:@adds) )
      end

      def outputs
        @outputs
      end

      # Call the actual {Process} with the options prepared in PublicCall.
      def __call__(args, circuit_options={})
        @process.( args, circuit_options.merge( exec_context: new ) )
      end
    end

    extend Process # make ::call etc. class methods on Operation.

    extend PublicCall              # ::call(params, { current_user: .. })
    extend Trace                   # ::trace

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

        cfg = @builder.send(type, *args, &block) # e.g. @builder.step
        recompile_process!
        cfg
      end
    end

    extend DSL

    include Railway::TaskWrap

    # The {Normalizer} is called for every DSL call (step/pass/fail etc.) and normalizes/defaults
    # the user options, such as setting `:id`, connecting the task's outputs or wrapping the user's
    # task via {TaskBuilder} in order to translate true/false to `Right` or `Left`.
    #
    # The Normalizer sits in the `@builder`, which receives all DSL calls from the Operation subclass.
    module Normalizer
      def self.call(task, options, sequence_options)
        wrapped_task, options =
          if task.is_a?(::Hash) # macro.
            [
              task[:task],
              task.merge(options) # Note that the user options are merged over the macro options.
            ]
          else # user step
            [
              Railway::TaskBuilder.(task),
              { id: task }.merge(options) # default :id
            ]
          end

        raise "No :id given for #{wrapped_task}" unless options[:id]

        options = defaultize(task, options) # :plus_poles

        options, locals, sequence_options = override(task, options, sequence_options) # :override

        return wrapped_task, options, sequence_options
      end

      # Merge user options over defaults.
      def self.defaultize(task, options)
        {
          plus_poles: InitialPlusPoles(),
        }.merge(options)
      end

      # Handle the :override option which is specific to Operation.
      def self.override(task, options, sequence_options)
        options, locals  = Activity::Magnetic::Builder.normalize(options, [:override])
        sequence_options = sequence_options.merge( replace: options[:id] ) if locals[:override]

        return options, locals, sequence_options
      end

      def self.InitialPlusPoles
        Activity::Magnetic::DSL::PlusPoles.new.merge(
          Activity.Output(Circuit::Right, :success) => nil,
          Activity.Output(Circuit::Left,  :failure) => nil,
        )
      end
    end

    initialize_builder!
  end
end

require "trailblazer/operation/inspect"
