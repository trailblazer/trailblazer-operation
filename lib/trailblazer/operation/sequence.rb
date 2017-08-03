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
      Row = Struct.new(:task, :name, :wirings)

      # Insert the task into {Sequence} array by respecting options such as `:before`.
      # This mutates the object per design.
      def insert!(task, options, wirings)
        row = Sequence::Row.new(task, options[:name], wirings)

        insert_for!(options, row)
      end

      private

      def insert_for!(options, row)
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
