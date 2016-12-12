require "pipetree"
require "pipetree/flow"
require "trailblazer/operation/result"
require "uber/option"

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
      includer._insert(:>>, New, name: "operation.new", wrap: false)
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
        self["pipetree"] = ::Pipetree::Flow.new
      end
    end

    module DSL
      # They all inherit.
      def >(*args); _insert(:>, *args) end
      def &(*args); _insert(:&, *args) end
      def <(*args); _insert(:<, *args) end

      # self.| ->(*) { }, before: "operation.new"
      # self.| :some_method
      def |(cfg, user_options={})
        DSL.import(self, self["pipetree"], cfg, user_options) &&
          heritage.record(:|, cfg, user_options)
      end

      alias_method :step,     :|
      alias_method :consider, :&
      alias_method :failure,  :<
      alias_method :success,  :>
      alias_method :override, :|
      alias_method :~, :override

      # :private:
      module Option
        def self.call(proc, &block)
          type = :proc

          option =
            if proc.is_a? Symbol
              type = :symbol
              ->(input, *_options) { input.send(proc, *_options) }
            elsif proc.is_a? Proc
              # ->(input, options) { proc.(**options) }
              ->(input, *_options) { proc.(*_options) }
            elsif proc.is_a? Uber::Callable
              type = :callable
              ->(input, *_options) { proc.(*_options) }
            end

          yield type if block_given?
          option
        end
      end

      # :public:
      # Wrap the step into a proc that only passes `options` to the step.
      # This is pure convenience for the developer and will be the default
      # API for steps. ATM, we also automatically generate a step `:name`.
      def self.insert(pipe, operator, proc, options={}, kws={}) # TODO: definer_name is a hack for debugging, only.
        # proc = Uber::Option[proc]
        _proc =
          if options[:wrap] == false
            proc
          else
            Option.(proc) do |type|
              options[:name] ||= proc if type == :symbol
              options[:name] ||= "#{kws[:definer_name]}:#{proc.source_location.last}" if proc.is_a? Proc if type == :proc
              options[:name] ||= proc.class  if type == :callable
            end
          end

        pipe.send(operator, _proc, options) # ex: pipetree.> Validate, after: Model::Build
      end

      def self.import(operation, pipe, cfg, user_options={})
        if cfg.is_a?(Array) # e.g. from Contract::Validate
          mod, args, block = cfg

          import = Import.new(pipe, user_options) # API object.

          return mod.import!(operation, import, *args, &block)
        end

        insert(pipe, :>, cfg, user_options, {}) # DOEES NOOOT calls heritage.record
      end


      # :private:
      # High-level user step API that allows ->(options) procs.
      def _insert(operator, proc, options={})
        heritage.record(:_insert, operator, proc, options)

        DSL.insert(self["pipetree"], operator, proc, options, definer_name: self.name)
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

  extend Pipetree::DSL::Macros
end
