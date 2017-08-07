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
      # Insert the task into {Sequence} array by respecting options such as `:before`.
      # This mutates the object per design.
      def insert!(task_wiring, options)
        return insert(find_index!(options[:before]),  task_wiring) if options[:before]
        return insert(find_index!(options[:after])+1, task_wiring) if options[:after]
        return self[find_index!(options[:replace])] = task_wiring  if options[:replace]
        return delete_at(find_index!(options[:delete]))    if options[:delete]

        self << task_wiring
      end

      private

      def find_index(id)
        task = find { |task_wiring| task_wiring.id == id }
        index(task)
      end

      def find_index!(id)
        find_index(id) or raise IndexError.new(id)
      end

      class IndexError < IndexError; end
    end
  end
end
