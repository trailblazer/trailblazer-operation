module Trailblazer
  module Operation::Railway
    # The {Normalizer} is called for every DSL call (step/pass/fail etc.) and normalizes/defaults
    # the user options, such as setting `:id`, connecting the task's outputs or wrapping the user's
    # task via {TaskBuilder} in order to translate true/false to `Right` or `Left`.
    #
    # The Normalizer sits in the `@builder`, which receives all DSL calls from the Operation subclass.
    class Normalizer
      def initialize(task_builder: TaskBuilder, activity: Pipeline, **options)
        @task_builder = task_builder
      end

      def call(task, options, unknown_options, sequence_options)
        ctx = {
          task: task, options: options, unknown_options: unknown_options, sequence_options: sequence_options,
          task_builder:       @task_builder,
          default_plus_poles: Normalizer.InitialPlusPoles(),
        }

        signal, (ctx, ) = Pipeline.( [ctx] )

        return ctx[:options][:task], ctx[:options], ctx[:unknown_options], ctx[:sequence_options]
      end

      # needs the basic Normalizer

      # :default_plus_poles is an injectable option.
      class Pipeline < Activity
        def self.normalize_extension_option( ctx, options:, ** )
          ctx[:options][:extension] = options[:extension] + [ Activity::Introspect.method(:add_introspection) ] # fixme: this sucks
        end

        def self.normalize_for_macro( ctx, task:, options:, task_builder:, ** )
          ctx[:options] =
            if task.is_a?(::Hash) # macro.
              options = options.merge(extension: (options[:extension]||[])+(task[:extension]||[]) ) # FIXME.

              task.merge(options) # Note that the user options are merged over the macro options.
            elsif task.is_a?(Array) # TODO remove in 2.2
              Operation::DeprecatedMacro.( *task )
            else # user step
              { id: task }
                .merge(options)                     # default :id
                .merge( task: task_builder.(task) )
            end
        end

        def self.raise_on_missing_id( ctx, options:, ** )
          raise "No :id given for #{options[:task]}" unless options[:id]
          true
        end

        # Merge user options over defaults.
        def self.defaultize( ctx, options:, default_plus_poles:, ** ) # TODO: test :default_plus_poles
          ctx[:options] =
            {
              plus_poles: default_plus_poles,
            }
            .merge(options)
        end

        # Handle the :override option which is specific to Operation.
        def self.override(ctx, task:, options:, sequence_options:, **)
          options, locals  = Activity::Magnetic::Options.normalize(options, [:override])
          sequence_options = sequence_options.merge( replace: options[:id] ) if locals[:override]

          ctx[:options], ctx[:sequence_options] = options, sequence_options
        end

        def self.deprecate_name(ctx, options:, unknown_options:, **) # TODO remove in 2.2
          unknown_options, deprecated_options = Activity::Magnetic::Options.normalize(unknown_options, [:name])

          options = options.merge( name: deprecated_options[:name] ) if deprecated_options[:name]

          options, locals = Activity::Magnetic::Options.normalize(options, [:name])
          if locals[:name]
            warn "[Trailblazer] The :name option for #step, #success and #failure has been renamed to :id."
            options = options.merge(id: locals[:name])
          end

          ctx[:options], ctx[:unknown_options] = options, unknown_options
        end

        task TaskBuilder.( method(:normalize_extension_option) )
        task TaskBuilder.( method(:normalize_for_macro) )
        task TaskBuilder.( method(:deprecate_name) )
        task TaskBuilder.( method(:raise_on_missing_id) )
        task TaskBuilder.( method(:defaultize) )
        task TaskBuilder.( method(:override) )
      end

      # @private Might be removed.
      def self.InitialPlusPoles
        Activity::Magnetic::DSL::PlusPoles.new.merge(
          Activity.Output(Activity::Right, :success) => nil,
          Activity.Output(Activity::Left,  :failure) => nil,
        )
      end
    end # Normalizer
  end
end
