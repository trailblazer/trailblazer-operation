require "pipetree"
require "pipetree/railway"
require "trailblazer/operation/result"

if RUBY_VERSION == "1.9.3"
  require "trailblazer/operation/1.9.3/option" # TODO: rename to something better.
else
  require "trailblazer/operation/option" # TODO: rename to something better.
end

class Trailblazer::Operation
  Instantiate = ->(klass, options) { klass.new(options) } # returns operation instance.

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

        # Any subclass of Right will be interpreted as successful.
        Result.new(!!(last <= Railway::Right), options)
      end

      # This method would be redundant if Ruby had a Class::finalize! method the way
      # Dry.RB provides it. It has to be executed with every subclassing.
      def initialize_pipetree!
        heritage.record :initialize_pipetree!

        self["pipetree"] = Railway.new

        strut = ->(last, input, options) { [last, Instantiate.(input, options)] } # first step in pipe.
        self["pipetree"].add(Railway::Right, strut, name: "operation.new") # DISCUSS: using pipe API directly here. clever?
      end
    end

    class Railway < ::Pipetree::Railway
      FailFast = Class.new(Left)
      PassFast = Class.new(Right)

      def self.fail!     ; Left     end
      def self.fail_fast!; FailFast end
      def self.pass!     ; Right    end
      def self.pass_fast!; PassFast end
    end

    # The Strut wrapping each step. Makes sure that Track signals are returned immediately.
    class Switch < ::Pipetree::Railway::Strut
      Decider = ->(result, config, *args) do
        return result if result.is_a?(Class) && result <= Railway::Track # this might be pretty slow?

        config[:decider_class].(result, config, *args) # e.g. And::Decider.(result, ..)
      end
    end

    # Strut that doesn't evaluate the step's result but stays on `last` or configured :signal.
    class Stay < ::Pipetree::Railway::Strut
      Decider = ->(result, config, last, *) { config[:signal] || last }
    end

    module DSL
      def success(*args); add(Railway::Right, Stay::Decider, *args) end
      def failure(*args); add(Railway::Left,  Stay::Decider, *args) end
      def step(*args)   ; add(Railway::Right, Railway::And::Decider, *args) end

    private
      # Operation-level entry point.
      def add(track, decider_class, proc, options={})
        heritage.record(:add, track, decider_class, proc, options)

        DSL.insert(self["pipetree"], track, decider_class, proc, options)
      end

      def self.insert(pipe, track, decider_class, proc, options={}) # TODO: make :name required arg.
        _proc, options = proc.is_a?(Array) ? macro!(proc, options) : step!(proc, options)

        options = options.merge(replace: options[:name]) if options[:override] # :override
        strut_class, strut_options = AddOptions.(decider_class, options)       # :fail_fast and friends.

        pipe.add(track, strut_class.new(_proc, strut_options), options)
      end

      def self.macro!(proc, options)
        _proc, macro_options = proc

        [ _proc, macro_options.merge(options) ]
      end

      def self.step!(proc, options)
        name  = ""
        _proc = Option::KW.(proc) do |type|
          name = proc if type == :symbol
          name = "#{proc.source_location[0].split("/").last}:#{proc.source_location.last}" if proc.is_a? Proc if type == :proc
          name = proc.class  if type == :callable
        end

        [ _proc, { name: name }.merge(options) ]
      end

      AddOptions = ->(decider_class, options) do
        # for #failure and #success:
        if decider_class == Stay::Decider
          return [Stay, signal: Railway::FailFast] if options[:fail_fast]
          return [Stay, signal: Railway::PassFast] if options[:pass_fast]
          return [Stay, {}]
        else # for #step:
          return [Switch, decider_class: decider_class, on_false: Railway::FailFast] if options[:fail_fast]
          return [Switch, decider_class: decider_class, on_true:  Railway::PassFast] if options[:pass_fast]
          return [Switch, decider_class: decider_class]
        end
      end
    end # DSL
  end

  require "uber/callable"
  # Allows defining dependencies and inject/override them via runtime options, if desired.
  class Pipetree::Step
    include Uber::Callable

    def initialize(step, dependencies={})
      @step, @dependencies = step, dependencies
    end

    def call(input, options)
      @dependencies.each { |k, v| options[k] ||= v } # not sure i like this, but the step's API is cool.

      @step.(input, options)
    end
  end
end
