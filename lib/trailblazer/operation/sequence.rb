module Trailblazer
  module Operation::Railway
    # Data object: The actual array that lines up the railway steps.
    # This is necessary mostly to maintain a linear representation of the wild circuit and can be
    # used to simplify inserting steps (without graph theory) and rendering (e.g. operation layouter).
    #
    # Gets converted into a Circuit/Activity via #to_activity.
    # @api private
    class Sequence < ::Array
      def alter!(options, row)
        return insert(find_index!(options[:before]),  row) if options[:before]
        return insert(find_index!(options[:after])+1, row) if options[:after]
        return self[find_index!(options[:replace])] = row  if options[:replace]
        return delete_at(find_index!(options[:delete])) if options[:delete]

        self << row
      end

      # Transform this Sequence into a new Activity.
      def to_activity(activity)
        each do |step_config|
          step = step_config.step

          # insert the new step before the track's End, taking over all its incoming connections.
          activity = Circuit::Activity::Before(
            activity,
            step_config.insert_before,
            step,
            direction: step_config.incoming_direction,
            debug: { step => step_config.options[:name] }
          ) # TODO: direction => outgoing

          # connect new task to End.left (if it's a step), or End.fail_fast, etc.
          step_config.connections.each do |(direction, target)|
            activity = Circuit::Activity::Connect(activity, step, direction, target)
          end
        end

        activity
      end

      private
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
