require "forwardable"
require "declarative"

require "trailblazer/activity"
require "trailblazer/activity/wrap"

require "trailblazer/operation/public_call"      # TODO: Remove in 3.0.
require "trailblazer/operation/skill"
require "trailblazer/operation/deprecated_macro" # TODO: remove in 2.2.
require "trailblazer/operation/result"
require "trailblazer/operation/railway"

require "trailblazer/operation/railway/dsl"
require "trailblazer/operation/railway/merge"

require "trailblazer/operation/railway/task_builder"
require "trailblazer/operation/railway/fast_track"
require "trailblazer/operation/task_wrap"
require "trailblazer/operation/trace"


require "trailblazer/activity/magnetic"

module Trailblazer
  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, skills, etc.
  class Operation
    # support for declarative inheriting (e.g. the circuit).
    extend Declarative::Heritage::Inherited
    extend Declarative::Heritage::DSL

    extend Skill::Accessors        # ::[] and ::[]=

    # include Railway                # ::call, ::step, ...
    # include Railway::TaskWrap

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
          track_end:   Railway::End::Success.new(:success),
          failure_end: Railway::End::Failure.new(:failure),
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
    class << self
      extend Forwardable
      def_delegators :@builder, :Output, :Path

      def step(*args, &block)
        heritage.record :step, *args, &block

        cfg = @builder.step(*args, &block)
        recompile_process!
        cfg
      end

      def pass(*args, &block)
        heritage.record :pass, *args, &block

        cfg = @builder.pass(*args, &block)
        recompile_process!
        cfg
      end

      def fail(*args, &block)
        heritage.record :fail, *args, &block

        cfg = @builder.fail(*args, &block)
        recompile_process!
        cfg
      end
    end

    # The {Normalizer} is called for every DSL call (step/pass/fail etc.) and normalizes/defaults
    # the user options, such as setting `:id`, connecting the task's outputs or wrapping the user's
    # task via {TaskBuilder} in order to translate true/false to `Right` or `Left`.
    #
    # The Normalizer sits in the `@builder`, which receives all DSL calls from the Operation subclass.
    class Normalizer
      def self.call(task, options, sequence_options)
        wrapped_task, options =
          if task.is_a?(::Hash) # macro.
            [ task[:task], task ]
          else # user step
            [ Railway::TaskBuilder.(task), options ]
          end

        options =
          {
            plus_poles: InitialPlusPoles(),
            id:         task, # TODO. :name, macro
          }.merge(options)


        # handle :override
        options, locals  = Activity::Magnetic::Builder.normalize(options, [:override])
        sequence_options = sequence_options.merge( replace: task ) if locals[:override]

        return wrapped_task, options, sequence_options
      end

      def self.InitialPlusPoles
        Activity::Magnetic::DSL::PlusPoles.new.merge(
          Activity::Magnetic.Output(Circuit::Right, :success) => nil,
          Activity::Magnetic.Output(Circuit::Left,  :failure) => nil,
        )
      end
    end

    initialize_builder!
  end
end

require "trailblazer/operation/inspect"
