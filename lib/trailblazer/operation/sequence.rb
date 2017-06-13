module Trailblazer
  module Operation::Railway
    # Array that lines up the railway steps and represents the {Activity} as a linear data structure.
    #
    # This is necessary mostly to maintain a linear representation of the wild circuit and can be
    # used to simplify inserting steps (without graph theory) and rendering (e.g. operation layouter).
    #
    # Gets converted into an {Alterations} via #to_alterations. It's your job on the outside to apply
    # those alterations to something.
    #
    # @api private
    class Sequence < ::Array
      StepRow = Struct.new(:step, :options, *DSL::StepArgs.members) # step, original_args, incoming_direction, ...

      # Insert the task into {Sequence} array by respecting options such as `:before`.
      # This mutates the object per design.
      def insert!(task, options, step_args)
        row = Sequence::StepRow.new(task, options, *step_args)

        alter!(options, row)
      end

      # Build a list of alterations for each step in the sequence.
      # This uses the {Activity::Alteration} API.
      # @returns Alterations
      def to_alterations
        each_with_object([]) do |step_config, alterations|
          step = step_config.step

          # insert the new step before the track's End, taking over all its incoming connections.
          alteration = ->(activity) do
            Circuit::Activity::Before(
              activity,
              activity[*step_config.insert_before_id], # e.g. activity[:End, :suspend]
              step,
              direction: step_config.incoming_direction,
              debug: { step => step_config.options[:name] }
            ) # TODO: direction => outgoing
          end
          alterations << alteration

          # connect new task to End.left (if it's a step), or End.fail_fast, etc.
          step_config.connections.each do |(direction, target)|
            alterations << ->(activity) { Circuit::Activity::Connect(activity, step, activity[*target], direction: direction) }
          end
        end
      end

      private

      def alter!(options, row)
        return insert(find_index!(options[:before]),  row) if options[:before]
        return insert(find_index!(options[:after])+1, row) if options[:after]
        return self[find_index!(options[:replace])] = row  if options[:replace]
        return delete_at(find_index!(options[:delete])) if options[:delete]

        self << row
      end

      def find_index(name)
        row = find { |row| row.options[:name] == name }
        index(row)
      end

      def find_index!(name)
        find_index(name) or raise IndexError.new(name)
      end

      class IndexError < IndexError; end
    end
  end
end
