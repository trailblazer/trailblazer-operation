module Trailblazer
  module Operation::DSL
    # Stores the graph altering commands for the insertion of one specific task/activity.
    # These are usually `insert_before` and `connect` invocations along with debug data.
    #
    # This data object can only be `call`ed which will apply the alterations. See {call}.
    class TaskWiring
      # assumptions FIXME: 1. the first wiring instruction produces the new node.
      def initialize(wirings, debug)
        @wirings = wirings
        @debug   = debug
      end

      #
      # It evaluates each option and substitutes placeholders with the currently inserted node.
      # This is per design since we want to keep the wiring in an abstract syntax (the array/hash structure)
      # and not a cryptic lambda.
      def call(graph)
        @wirings.each do |wiring|
          # wiring.last[:node] = [ task, options ] if wiring.last.key?(:node) && wiring.last[:node].nil? # FIXME: this is only needed for insert_before!
          # wiring.last[:source] = options[:id] if wiring.last[:source]=="fixme!!!" # FIXME: this is only needed for connect!

          p wiring

          graph.send *wiring # apply the wiring by calling graph.insert_before!, etc.
        end
      end
    end # TaskWiring
  end
end
