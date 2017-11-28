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
    extend PublicCall              # ::call(params, { current_user: .. })

    extend Trace                   # ::trace


    def self.inherited(inheriter)
      inheriter.initialize_activity_dsl!
      inheriter.recompile_process!
    end

    def self.initialize_activity_dsl!
      @builder = Activity::Magnetic::Builder::FastTrack.new( Normalizer, {} )
    end

    def self.recompile_process!
      @process, @outputs = Activity::Magnetic::Builder::FastTrack.finalize( @builder.instance_variable_get(:@adds) )
    end

    def self.outputs
      @outputs
    end

    def self.call(args, circuit_options={})
      @process.( args, circuit_options.merge( exec_context: new ) )
    end

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
    # the user options, such as setting `:id` or connecting the task's outputs.
    #
    # The Normalizer sits in the `@builder`, which receives all DSL calls.
    class Normalizer
      def self.call(task, options)
        options =
          {
            plus_poles: InitialPlusPoles(),
            id:         task.inspect, # TODO.
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
