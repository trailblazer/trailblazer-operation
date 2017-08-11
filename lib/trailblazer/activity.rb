module Trailblazer
  class Activity
    Q_Operation = Operation
    def self.from_wirings(wirings)
      start_evt = Circuit::Start.new(:default)
      start     = Q_Operation::Graph::Node( start_evt, type: :event, id: [:Start, :default] )

      wirings.each do |wiring|
        start.send(*wiring)
      end

      new(start)
    end

    def initialize(graph)
      @graph = graph
      @start = @graph[:_wrapped]
    end

    def to_circuit
      end_events = @graph.find_all { |node| node.successors.size == 0 } # Find leafs of graph.
        .collect { |n| n[:_wrapped] } # unwrap the actual End event instance from the Node.

      Circuit.new(@graph.to_h( include_leafs: false ), end_events, {})
    end
  end
end
