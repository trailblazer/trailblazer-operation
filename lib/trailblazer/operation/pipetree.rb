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
  # http://trailblazer.to/gems/operation/2.0/pipetree.html
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
    end

    class Switch # Tie
      def initialize(proc, decider, options)
        @proc    = proc
        @decider = decider
        @stay    = options[:stay]
      end

      def call(last, input, options)
        result = @proc.(input, options)

        # if step returns a Track constant, always instantly return this.
        return result if result.is_a?(Class) && result <= Flow::Track


        # FIXME: THIS SUCKS, that's Stay and And repeated.
        track = @stay ? last : @decider.(result)

        [track, input]
      end

      Decider = ->(result) do

        # And logic:
        result ? Flow::Right : Flow::Left
      end
    end

    module DSL
      # They all inherit.
      def success(*args); add(Flow::Right, Flow::Stay, *args) end
      def failure(*args); add(Flow::Left,  Flow::Stay, *args) end
      def step(*args)   ; add(Flow::Right, Flow::And,  *args) end

      alias_method :override, :step

    private
      # Operation-level entry point.
      def add(track, strut_class, proc, options={})
        heritage.record(:add, track, strut_class, proc, options)

        DSL.insert(self, self["pipetree"], track, strut_class, proc, options)
      end

      # TODO: REMOVE operation ARGUMENT.
      def self.insert(operation, pipe, track, strut_class, proc, options={})
        return DSL.import(operation, pipe, proc, options) if proc.is_a?(Array) # TODO: remove that!

        _proc = Option::KW.(proc) do |type|
          options[:name] ||= proc if type == :symbol
          options[:name] ||= "#{proc.source_location[0].split("/").last}:#{proc.source_location.last}" if proc.is_a? Proc if type == :proc
          options[:name] ||= proc.class  if type == :callable
        end

        # TODO: ALLOW for macros, too.
        strut_args = []
        if options[:fail_fast] == true
          strut_class = Flow::And
          strut_args << { on_true: Flow::FailFast, on_false: Flow::FailFast } # PoC.

        else
          strut_args << Switch::Decider
          strut_args << (strut_class==Flow::Stay ? { stay: true } : {})

          strut_class = Switch
        end

        pipe.add(track, strut_class.new(_proc, *strut_args), options) # ex: pipetree.> Validate, after: Model::Build
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

    module Step
      def self.fail!     ; Flow::Left     end
      def self.fail_fast!; Flow::FailFast end
      def self.pass!     ; Flow::Right    end
      def self.pass_fast!; Flow::PassFast end
    end
  end

  Step = Pipetree::Step

  extend Pipetree::DSL::Macros
end
