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
        def self.deprecate_name(ctx, options:, connection_options:, **)
          connection_options, deprecated_options = Activity::Magnetic::Options.normalize(connection_options, [:name])

          options = options.merge( name: deprecated_options[:name] ) if deprecated_options[:name]

          options, locals = Activity::Magnetic::Options.normalize(options, [:name])
          if locals[:name]
            warn "[Trailblazer] The :name option for #step, #success and #failure has been renamed to :id."
            options = options.merge(id: locals[:name])
          end

          ctx[:options], ctx[:connection_options] = options, connection_options
        end

        # add more normalization tasks to the existing Magnetic::Normalizer::Pipeline
        task Activity::TaskBuilder::Binary.( method(:deprecate_macro_with_two_args) ), before: "split_options"
        task Activity::TaskBuilder::Binary.( method(:deprecate_name) )
        task Activity::TaskBuilder::Binary.( method(:override) )
      end
    end # Normalizer
  end
end
