module Trailblazer
  module Operation::Railway
    # The {Normalizer} is called for every DSL call (step/pass/fail etc.) and normalizes/defaults
    # the user options, such as setting `:id`, connecting the task's outputs or wrapping the user's
    # task via {TaskBuilder} in order to translate true/false to `Right` or `Left`.
    #
    # The Normalizer sits in the `@builder`, which receives all DSL calls from the Operation subclass.
    module Normalizer
      Pipeline = Activity::Magnetic::Normalizer::Pipeline.clone

      Pipeline.module_eval do
        # Handle the :override option which is specific to Operation.
        def self.override(ctx, task:, options:, sequence_options:, **)
          options, locals  = Activity::Magnetic::Options.normalize(options, [:override])
          sequence_options = sequence_options.merge( replace: options[:id] ) if locals[:override]

          ctx[:options], ctx[:sequence_options] = options, sequence_options
        end

        # TODO remove in 2.2
        def self.deprecate_macro_with_two_args(ctx, task:, **)
          return true unless task.is_a?(Array) # TODO remove in 2.2

          ctx[:options] = Operation::DeprecatedMacro.( *task )
        end

        # TODO remove in 2.2
        def self.deprecate_name(ctx, local_options:, connection_options:, **)
          connection_options, deprecated_options = Activity::Magnetic::Options.normalize(connection_options, [:name])
          local_options, _deprecated_options     = Activity::Magnetic::Options.normalize(local_options, [:name])

          deprecated_options = deprecated_options.merge(_deprecated_options)

          local_options = local_options.merge( name: deprecated_options[:name] ) if deprecated_options[:name]

          local_options, locals = Activity::Magnetic::Options.normalize(local_options, [:name])
          if locals[:name]
            warn "[Trailblazer] The :name option for #step, #success and #failure has been renamed to :id."
            local_options = local_options.merge(id: locals[:name])
          end

          ctx[:local_options], ctx[:connection_options] = local_options, connection_options
        end

        def self.raise_on_missing_id(ctx, local_options:, **)
          raise "No :id given for #{local_options[:task]}" unless local_options[:id]
          true
        end

        # add more normalization tasks to the existing Magnetic::Normalizer::Pipeline
        task Activity::TaskBuilder::Binary( method(:deprecate_macro_with_two_args) ), before: "split_options"
        task Activity::TaskBuilder::Binary( method(:deprecate_name) )
        task Activity::TaskBuilder::Binary( method(:override) )
        task Activity::TaskBuilder::Binary( method(:raise_on_missing_id) )
      end
    end # Normalizer
  end
end
