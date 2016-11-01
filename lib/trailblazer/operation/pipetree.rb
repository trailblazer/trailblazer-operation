require "pipetree"
require "pipetree/flow"

class Trailblazer::Operation
  New  = ->(klass, options)     { klass.new(options) }                # returns operation instance.
  Call = ->(operation, options) { operation.call(options["params"]) } # returns #call result.

  module Pipetree
    def self.included(includer)
      includer.extend ClassMethods
      includer.extend Pipe

      includer.>> New, nil
      includer.>> Call, nil
    end

    module ClassMethods
      # Top-level, this method is called when you do Create.() and where
      # all the fun starts.
      def call(options)
        pipe = self["pipetree"] # TODO: injectable? WTF? how cool is that?

        outcome = pipe.(self, options)
        outcome.last
      end
    end

    module Pipe
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
  end
end

# TODO: test in pipetree_test the outcome of returning Stop. it's only implicitly tested with Policy.
