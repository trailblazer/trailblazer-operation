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
      def connect!(node:raise, edge:raise)
        node = node.kind_of?(Node) ? node : Node(*node)
        edge = Edge(*edge)

        self[:graph][self][edge] = node
        node
      end

      def insert_before!(old_node, node:raise, outgoing:nil, incoming:, **)
        new_node            = Node(*node)
        incoming_tuples     = old_node.predecessors
        rewired_connections = incoming_tuples.find_all { |(node, edge)| incoming.(edge) }

        # rewire old_task's predecessors to new_task.
        rewired_connections.each { |(node, edge)| self[:graph][node][edge] = new_node }

        # connect new_task --> old_task.
        if outgoing
          new_to_old_edge = Edge(*outgoing)
          self[:graph][new_node] = { new_to_old_edge => old_node }
        end

        return new_node, new_to_old_edge
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

  module Operation::Railway
    # Array that lines up the railway steps and represents the {Activity} as a linear data structure.
    #
    # This is necessary mostly to maintain a linear representation of the wild circuit and can be
    # used to simplify inserting steps (without graph theory) and rendering (e.g. operation layouter).
    #
    # Gets converted into {Alterations} via #to_alterations. It's your job on the outside to apply
    # those alterations to something.
    #
    # @api private
    class Sequence < ::Array
      # Configuration for alter!, represents one sequence/circuit alteration. Usually per `step`.
      Row = Struct.new(:task, :name, :insert_before_id, :connections, :incoming_direction, :predecessors)

      # Insert the task into {Sequence} array by respecting options such as `:before`.
      # This mutates the object per design.
      def insert!(task, name, options, insert_before_id:raise, connections:raise, incoming_direction:raise, **)
        row = Sequence::Row.new(task, name, insert_before_id, connections, incoming_direction)

        alter!(options, row)
      end

      def self.find_linear_inputs(activity, task)

      end

      # Build a list of alterations for each step in the sequence.
      # This uses the {Activity::Alteration} API.
      # @returns Alterations
      def to_alterations
        each_with_object([]) do |row, alterations|
          task = row.task

          # insert the new task before the track's End, taking over all its incoming connections.
          alteration = ->(activity) do
            Circuit::Activity::Before(
              activity,
              activity[*row.insert_before_id], # e.g. activity[:End, :suspend]
              task,
              direction: row.incoming_direction,
              debug: { task => row.name }
            ) # TODO: direction => outgoing
          end
          alterations << alteration

          # connect new task to End.left (if it's a task), or End.fail_fast, etc.
          row.connections.each do |(direction, target)|
            alterations << ->(activity) { Circuit::Activity::Connect(activity, task, activity[*target], direction: direction) }
          end
        end
      end

      private

      def alter!(options, row)
        return insert(find_index!(options[:before]),  row) if options[:before]
        return insert(find_index!(options[:after])+1, row) if options[:after]
        return self[find_index!(options[:replace])] = row  if options[:replace]
        return delete_at(find_index!(options[:delete]))    if options[:delete]

        self << row
      end

      def find_index(name)
        row = find { |row| row.name == name }
        index(row)
      end

      def find_index!(name)
        find_index(name) or raise IndexError.new(name)
      end

      class IndexError < IndexError; end
    end
  end
end
