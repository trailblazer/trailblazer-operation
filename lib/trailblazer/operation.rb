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
    # include Railway::FastTrack
    # include Railway::TaskWrap

    # we want the skill dependency-mechanism.
    # extend Skill::Call             # ::call(params: .., current_user: ..)



    module Process
      def inherited(inheriter)
        inheriter.initialize_activity_dsl!
        inheriter.recompile_process!
      end

      def initialize_activity_dsl!
        @builder = Activity::Magnetic::Builder::FastTrack.new( Normalizer, {} )
      end

      def recompile_process!
        @process, @outputs = Activity::Magnetic::Builder::FastTrack.finalize( @builder.instance_variable_get(:@adds) )
      end

      def outputs
        @outputs
      end

      def call(args, circuit_options={})
        @process.( args, circuit_options.merge( exec_context: new ) )
      end
    end

    module Call
    # Low-level `Activity` call interface. Runs the circuit.
        #
        # @param options [Hash, Skill] options to be passed to the first task. These are usually the "runtime options".
        # @param flow_options [Hash] arbitrary flow control options.
        # @return direction, options, flow_options
        def __call__( (options, *args), **circuit_options )
          # add the local operation's class dependencies to the skills.
          immutable_options = Trailblazer::Context::ContainerChain.new([options, self.skills]) # TODO: make this a separate feature, non-default.

          ctx = Trailblazer::Context(immutable_options)

          signal, args = self["__activity__"].( [ ctx, *args ], **circuit_options.merge( exec_context: new ) )

          [ signal, args ]
        end

        # This method gets overridden by PublicCall#call which will provide the Skills object.
        # @param options [Skill,Hash] all dependencies and runtime-data for this call
        # @return see #__call__
        def call(*args)
          __call__( args )
        end
    end

    extend Process # make ::call etc. class methods on Operation.
    extend PublicCall              # ::call(params, { current_user: .. })
    extend Trace                   # ::trace

    # DSL part
    # delegate as much as possible to Builder
    # let us process options and e.g. do :id
    class << self
      extend Forwardable
      def_delegators :@builder, :Output, :Path#, :task

      def step(*args, &block)
        cfg = @builder.step(*args, &block)
        recompile_process!
        cfg
      end

      def pass(*args, &block)
        cfg = @builder.pass(*args, &block)
        recompile_process!
        cfg
      end

      def fail(*args, &block)
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
      def self.call(task, options)
        task = Railway::TaskBuilder.(task)

        options =
          {
            plus_poles: InitialPlusPoles(),
            id:         task.inspect, # TODO. :name, macro
          }.merge(options)

        return task, options
      end

      def self.InitialPlusPoles
        Activity::Magnetic::DSL::PlusPoles.new.merge(
          Activity::Magnetic.Output(Circuit::Right, :success) => nil,
          Activity::Magnetic.Output(Circuit::Left,  :failure) => nil,
        )
      end
    end
  end
end

require "trailblazer/operation/inspect"
