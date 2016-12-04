require "pipetree"
require "pipetree/flow"
require "trailblazer/operation/result"
require "uber/option"

class Trailblazer::Operation
  New = ->(klass, options)     { klass.new(options) } # returns operation instance.

  # Implements the API to populate the operation's pipetree and
  # `Operation::call` to invoke the latter.
  # http://trailblazer.to/gems/operation/2.0/pipetree.html
  module Pipetree
    def self.included(includer)
      includer.extend ClassMethods # ::call, ::inititalize_pipetree!
      includer.extend DSL          # ::|, ::> and friends.

      includer.initialize_pipetree!
      includer.>> New, name: "operation.new", wrap: false
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
        Result.new(last == ::Pipetree::Flow::Right, options)
      end

      # This method would be redundant if Ruby had a Class::finalize! method the way
      # Dry.RB provides it. It has to be executed with every subclassing.
      def initialize_pipetree!
        heritage.record :initialize_pipetree!
        self["pipetree"] = ::Pipetree::Flow[]
      end
    end

    module DSL
      # They all inherit.
      def >>(*args); _insert(:>>, *args) end
      def >(*args); _insert(:>, *args) end
      def &(*args); _insert(:&, *args) end
      def <(*args); _insert(:<, *args) end

      # :private:
      # High-level user step API that allows ->(options) procs.
      def _insert(operator, proc, options={})
        heritage.record(:_insert, operator, proc, options)

        # proc = Uber::Option[proc]
        _proc =
          if options[:wrap] == false
            proc
          elsif proc.is_a? Symbol
            options[:name] ||= proc
            ->(input, _options) { input.send(proc, _options) }
          elsif proc.is_a? Proc
            options[:name] ||= "#{self.name}:#{proc.source_location.last}" if proc.is_a? Proc
            # ->(input, options) { proc.(**options) }
            ->(input, _options) { proc.(_options) }
          elsif proc.is_a? Uber::Callable
            options[:name] ||= proc.class
            ->(input, _options) { proc.(_options) }
          end

        self["pipetree"].send(operator, _proc, options) # ex: pipetree.> Validate, after: Model::Build
      end

      def ~(cfg)
        heritage.record(:~, cfg)

        self.|(cfg, inheriting: true) # FIXME: not sure if this is the final API.
      end

      def |(cfg, user_options={})
        if cfg.is_a?(Array) # e.g. Contract::Validate
          mod, args, block = cfg

          import = Import.new(self, user_options) # API object.

          return mod.import!(self, import, *args, &block) &&
            heritage.record(:|, cfg, user_options)
        end

        self.> cfg, user_options # calls heritage.record
      end

      # Try to abstract as much as possible from the imported module. This is for
      # forward-compatibility.
      # Note that Import#call will push the step directly on the pipetree which gives it the
      # low-level (input, options) interface.
      Import = Struct.new(:operation, :user_options) do
        def call(operator, step, options)
          operation["pipetree"].send operator, step, options.merge(user_options)
        end

        def inheriting?
          user_options[:inheriting]
        end
      end
    end
  end
end
