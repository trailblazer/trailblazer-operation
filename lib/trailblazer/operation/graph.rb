module Trailblazer
  module Operation::Graph
    class Edge
      def initialize(data)
        yield self, data if block_given?
        @data = data
      end

      def [](key)
        @data[key]
      end
    end

    class Node < Edge
      # Builds a node from the provided `:node` argument array.
      def attach!(node:raise, edge:raise)
        node = node.kind_of?(Node) ? node : Node(*node)

        connect!(node: node, edge: edge)
      end

      def connect!(node:raise, edge:raise)
        node = node.kind_of?(Node) ? node : (find_all { |_node| _node[:id] == node }[0] || raise( "#{node} not found"))
        edge = Edge(*edge)

        self[:graph][self][edge] = node
        node
      end

      def insert_before!(old_node, node:raise, outgoing:nil, incoming:, **)
        old_node = find_all(old_node)[0] unless old_node.kind_of?(Node)

        new_node            = Node(*node)
        incoming_tuples     = old_node.predecessors
        rewired_connections = incoming_tuples.find_all { |(node, edge)| incoming.(edge) }

        # rewire old_task's predecessors to new_task.
        rewired_connections.each { |(node, edge)| self[:graph][node][edge] = new_node }

        # connect new_task --> old_task.
        connections = if outgoing
          new_to_old_edge = Edge(*outgoing)
          { new_to_old_edge => old_node }
        else
          {}
        end
        self[:graph][new_node] = connections

        return new_node, new_to_old_edge
      end

      def find_all(id=nil, &block)
        nodes = self[:graph].keys + self[:graph].values.collect(&:values).flatten

        block ||= ->(node) { node[:id] == id }

        nodes.find_all(&block)
      end

      def Edge(wrapped, options)
        edge = Edge.new(options.merge( graph: self[:graph], _wrapped: wrapped ))
      end

      def Node(wrapped, options)
        Node.new( options.merge( graph: self[:graph], _wrapped: wrapped ) )
      end

      # private
      def predecessors
        self[:graph].each_with_object([]) do |(node, connections), ary|
          connections.each { |edge, target| target == self && ary << [node, edge] }
        end
      end

      def successors
        ( self[:graph][self] || {} ).values
      end

      def to_h
        ::Hash[
          self[:graph].collect do |node, connections|
            connections = connections.collect { |edge, node| [ edge[:_wrapped], node[:_wrapped] ] }

            [ node[:_wrapped], ::Hash[connections] ]
          end
        ]
      end
    end

    def self.Node(wrapped, data={})
      Node.new( { _wrapped: wrapped, graph: {} }.merge(data) ) { |node, data| data[:graph][node] = {} }
    end

  end
end
