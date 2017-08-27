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
      Element = Struct.new(:id, :instructions)

      # Insert the task into {Sequence} array by respecting options such as `:before`.
      # This mutates the object per design.
      # @param element_wiring ElementWiring Set of instructions for a specific element in an activity graph.
      def insert!(id, wiring, before:nil, after:nil, replace:nil, delete:nil)
        element = Element.new(id, wiring).freeze

        return insert(find_index!(before),  element) if before
        return insert(find_index!(after)+1, element) if after
        return self[find_index!(replace)] = element  if replace
        return delete_at(find_index!(delete))    if delete

        self << element
      end

      def to_a
        collect { |element| element.instructions }.flatten(1)
      end

      private

      def find_index(id)
        element = find { |el| el.id == id }
        index(element)
      end

      def find_index!(id)
        find_index(id) or raise IndexError.new(id)
      end

      class IndexError < IndexError; end
    end
  end
end
