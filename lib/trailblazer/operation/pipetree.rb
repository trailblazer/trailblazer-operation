require "pipetree"
require "pipetree/flow"
require "trailblazer/operation/result"

class Trailblazer::Operation
  New  = ->(klass, options)     { klass.new(options) }                # returns operation instance.
  Call = ->(operation, options) { operation.call(options["params"]) } # returns #call result.

  module Pipetree
    def self.included(includer)
      includer.extend ClassMethods
      includer.extend Pipe
      includer.extend DSLOperators

      includer.>> New, name: "operation.new"
    end

    module ClassMethods
      # Top-level, this method is called when you do Create.() and where
      # all the fun starts, ends, and hopefully starts again.
      def call(options)
        pipe = self["pipetree"] # TODO: injectable? WTF? how cool is that?

        last, operation = pipe.(self, options) # operation == self, usually.

        Result.new(last == ::Pipetree::Flow::Right, operation)
      end
    end

    module Pipe
      # They all inherit.
      def >>(*args); _insert(:>>, *args) end
      def >(*args); _insert(:>, *args) end
      def &(*args); _insert(:&, *args) end
      def <(*args); _insert(:<, *args) end

      # :private:
      def _insert(*args)
        heritage.record(:_insert, *args)

        self["pipetree"] ||= ::Pipetree::Flow[]
        self["pipetree"].send(*args) # ex: pipetree.> Validate, after: Model::Build
      end
    end

    module DSLOperators
      def ~(cfg)
        heritage.record(:~, cfg)

        self.|(cfg)
      end

      def |(cfg, *args)
        if cfg.is_a?(Stepable::Configuration)
          cfg[:module].import!(self, *cfg.args) and
            heritage.record(:|, cfg, *args)
          return
        end

        self.>(cfg, *args)
      end
    end
  end
end
