module Trailblazer
  module Operation::Railway
    # The {Normalizer} is called for every DSL call (step/pass/fail etc.) and normalizes/defaults
    # the user options, such as setting `:id`, connecting the task's outputs or wrapping the user's
    # task via {TaskBuilder} in order to translate true/false to `Right` or `Left`.
    #
    # The Normalizer sits in the `@builder`, which receives all DSL calls from the Operation subclass.
    class Normalizer
      def initialize(task_builder: TaskBuilder, **options)
        @task_builder = task_builder
      end

      def call(task, options, unknown_options, sequence_options)
        options[:extension] = options[:extension] + [ Activity::Introspect.method(:add_introspection) ] # fixme: this sucks

        wrapped_task, options =
          if task.is_a?(::Hash) # macro.
            options = options.merge(extension: (options[:extension]||[])+(task[:extension]||[]) ) # FIXME.

            [
              task[:task],
              task.merge(options) # Note that the user options are merged over the macro options.
            ]
          elsif task.is_a?(Array) # TODO remove in 2.2
            Operation::DeprecatedMacro.( *task )
          else # user step
            [
              @task_builder.(task),
              { id: task }.merge(options) # default :id
            ]
          end

        options, unknown_options = deprecate_name(options, unknown_options) # TODO remove in 2.2

        raise "No :id given for #{wrapped_task}" unless options[:id]

        options = defaultize(task, options) # :plus_poles

        options, locals, sequence_options = override(task, options, sequence_options) # :override
        return wrapped_task, options, unknown_options, sequence_options
      end

      # Merge user options over defaults.
      def defaultize(task, options)
        {
          plus_poles: InitialPlusPoles(),
        }.merge(options)
      end

      # Handle the :override option which is specific to Operation.
      def override(task, options, sequence_options)
        options, locals  = Activity::Magnetic::Options.normalize(options, [:override])
        sequence_options = sequence_options.merge( replace: options[:id] ) if locals[:override]

        return options, locals, sequence_options
      end

      def InitialPlusPoles
        Activity::Magnetic::DSL::PlusPoles.new.merge(
          Activity.Output(Activity::Right, :success) => nil,
          Activity.Output(Activity::Left,  :failure) => nil,
        )
      end

      def deprecate_name(options, unknown_options) # TODO remove in 2.2
        unknown_options, deprecated_options = Activity::Magnetic::Options.normalize(unknown_options, [:name])

        options = options.merge( name: deprecated_options[:name] ) if deprecated_options[:name]

        options, locals = Activity::Magnetic::Options.normalize(options, [:name])
        if locals[:name]
          warn "[Trailblazer] The :name option for #step, #success and #failure has been renamed to :id."
          options = options.merge(id: locals[:name])
        end
        return options, unknown_options
      end
    end
  end
end
