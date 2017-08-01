module Trailblazer
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
