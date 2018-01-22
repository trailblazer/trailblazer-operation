module Trailblazer
  module Operation::Wrap
    module Inject
      # Returns an Alteration wirings that, when applied, inserts the {ReverseMergeDefaults} task
      # before the {Wrap::Call} task. This is meant for macros and steps that accept a dependency
      # injection but need a default parameter to be set if not injected.
      # @returns ADDS
      def self.Defaults(default_dependencies)
        Module.new do
          extend Activity::Path::Plan()

          task ReverseMergeDefaults.new( default_dependencies ),
            id:     "ReverseMergeDefaults#{default_dependencies}",
            before: "task_wrap.call_task"
        end
      end

      # @api private
      # @returns Task
      # @param Hash list of key/value that should be set if not already assigned/set before (or injected from the outside).
      class ReverseMergeDefaults
        def initialize(defaults)
          @defaults = defaults
        end

        def call((wrap_ctx, original_args), **circuit_options)
          ctx = original_args[0][0]

          @defaults.each { |k, v| ctx[k] ||= v }

          return Activity::Right, [ wrap_ctx, original_args ]
        end
      end
    end # Inject
  end
end
