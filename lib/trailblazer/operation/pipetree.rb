require "pipetree"
require "pipetree/flow"
require "trailblazer/operation/result"
require "uber/option"

if RUBY_VERSION == "1.9.3"
  require "trailblazer/operation/1.9.3/option" # TODO: rename to something better.
else
  require "trailblazer/operation/option" # TODO: rename to something better.
end

class Trailblazer::Operation
  New = ->(klass, options) { klass.new(options) } # returns operation instance.

  # Implements the API to populate the operation's pipetree and
  # `Operation::call` to invoke the latter.
  # Learn more about the Pipetree gem here: https://github.com/apotonick/pipetree
  module Pipetree
    def self.included(includer)
      includer.extend ClassMethods # ::call, ::inititalize_pipetree!
      includer.extend DSL          # ::|, ::> and friends.

      includer.initialize_pipetree!
    end

    module ClassMethods
      # Top-level, this method is called when you do Create.() and where
      # all the fun starts, ends, and hopefully starts again.
      def call(options)
        pipe = self["pipetree"] # TODO: injectable? WTF? how cool is that?

        last, operation = pipe.(self, options)

        # The reason the Result wraps the Skill object (`options`), not the operation
        # itself is because the op should be irrelevant, plus when stopping the pipe
        # before op instantiation, this would be confusing (and wrong!).
        Result.new(!!(last <= Flow::Right), options)
      end

      # This method would be redundant if Ruby had a Class::finalize! method the way
      # Dry.RB provides it. It has to be executed with every subclassing.
      def initialize_pipetree!
        heritage.record :initialize_pipetree!

        self["pipetree"] = Flow.new

        strut = ->(last, input, options) { [last, New.(input, options)] } # first step in pipe.
        self["pipetree"].add(Flow::Right, strut, name: "operation.new") # DISCUSS: using pipe API directly here. clever?
      end
    end

    class Flow < ::Pipetree::Flow
      FailFast = Class.new(Left)
      PassFast = Class.new(Right)

      def self.fail!     ; Left     end
      def self.fail_fast!; FailFast end
      def self.pass!     ; Right    end
      def self.pass_fast!; PassFast end
    end

    # The Tie wrapping each step. Makes sure that Track signals are returned immediately.
    class Switch < ::Pipetree::Flow::Tie
      Decider = ->(result, config, *args) do
        return result if result.is_a?(Class) && result <= Flow::Track # this might be pretty slow?

        config[:decider_class].(result, config, *args) # e.g. And::Decider.(result, ..)
      end
    end

    module DSL
      # They all inherit.
      def success(*args); add(Flow::Right, Flow::Stay::Decider, *args) end
      def failure(*args); add(Flow::Left,  Flow::Stay::Decider, *args) end
      def step(*args)   ; add(Flow::Right, Flow::And::Decider,  *args) end

      alias_method :override, :step

    private
      # Operation-level entry point.
      def add(track, decider_class, proc, options={})
        heritage.record(:add, track, decider_class, proc, options)

        DSL.insert(self, self["pipetree"], track, decider_class, proc, options)
      end

      # TODO: REMOVE operation ARGUMENT.
      def self.insert(operation, pipe, track, decider_class, proc, options={})
        return DSL.import(operation, pipe, proc, options) if proc.is_a?(Array) # TODO: remove that!

        _proc = Option::KW.(proc) do |type|
          options[:name] ||= proc if type == :symbol
          options[:name] ||= "#{proc.source_location[0].split("/").last}:#{proc.source_location.last}" if proc.is_a? Proc if type == :proc
          options[:name] ||= proc.class  if type == :callable
        end

        if decider_class == Flow::Stay::Decider
          return pipe.add(track, Flow::And.new(_proc, on_true: Flow::FailFast, on_false: Flow::FailFast), options) if options[:fail_fast]
          return pipe.add(track, Flow::Stay.new(_proc), options)
          # only wrap if :fail_fast or :pass_fast
        else # And
          return pipe.add(track, Switch.new(_proc, decider_class: Flow::And::Decider, on_true: Flow::Right, on_false: Flow::FailFast), options) if options[:fail_fast]
          return pipe.add(track, Switch.new(_proc, decider_class: Flow::And::Decider, on_true: Flow::PassFast, on_false: Flow::Left), options) if options[:pass_fast]
          return pipe.add(track, Switch.new(_proc, decider_class: Flow::And::Decider), options)
          # Switch.new # handles all signals
          # handle :fail_fast and :pass_fast, too, here
        end

        # TODO: ALLOW for macros, too.
        if options[:fail_fast] == true
          # step: only FailFast when false
          # fail: always FailFast
          tie_args = { decider_class: Flow::And::Decider, on_true: Flow::FailFast, on_false: Flow::FailFast } # PoC.
        else
          tie_args = { decider_class: decider_class }
        end

        pipe.add(track, Switch.new(_proc, tie_args), options) # ex: pipetree.> Validate, after: Model::Build
      end

      def self.import(operation, pipe, cfg, user_options={})
        # e.g. from Contract::Validate
        mod, args, block = cfg

        import = Import.new(pipe, user_options) # API object.

        mod.import!(operation, import, *args, &block)
      end

      # Try to abstract as much as possible from the imported module. This is for
      # forward-compatibility.
      # Note that Import#call will push the step directly on the pipetree which gives it the
      # low-level (input, options) interface.
      Import = Struct.new(:pipetree, :user_options) do
        def call(operator, step, options)
          insert_options = options.merge(user_options)

          # Inheritance: when the step is already defined in the pipe,
          # simply replace it with the new.
          if name = insert_options[:name]
            insert_options[:replace] = name if pipetree.index(name)
          end

          pipetree.send operator, step, insert_options
        end
      end

      Macros = Module.new
      # create a class method on `target`, e.g. Contract::Validate() for step macros.
      def self.macro!(name, constant, target=Macros)
        target.send :define_method, name do |*args, &block|
          [constant, args, block]
        end
      end
    end # DSL
  end

  Flow = Pipetree::Flow

  extend Pipetree::DSL::Macros
end
