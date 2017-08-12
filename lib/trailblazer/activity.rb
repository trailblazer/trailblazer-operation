module Trailblazer
  class Activity
    Q_Operation = Operation
    # Only way to build an Activity.
    def self.from_wirings(wirings)
      start_evt = Circuit::Start.new(:default)
      start     = Q_Operation::Graph::Node( start_evt, type: :event, id: [:Start, :default] )

      wirings.each do |wiring|
        start.send(*wiring)
      end

      new(start)
    end

    def initialize(graph)
      @graph       = graph
      @start_event = @graph[:_wrapped]
      @circuit     = to_circuit
    end

    def call(start_at, *args)
      @circuit.( @start_event, *args )
    end

    # @private
    attr_reader :circuit
    # @private
    attr_reader :graph

    private

    def to_circuit
      end_events = @graph.find_all { |node| node.successors.size == 0 } # Find leafs of graph.
        .collect { |n| n[:_wrapped] } # unwrap the actual End event instance from the Node.

      Circuit.new(@graph.to_h( include_leafs: false ), end_events, {})
    end

    class Introspection
      # @param activity Activity
      def initialize(activity)
        @graph = activity.graph
      end

      def [](task)
        (node = @graph.find_all { |node| node[:_wrapped] == task  }.first) ? node : task
      end
    end
  end
end
