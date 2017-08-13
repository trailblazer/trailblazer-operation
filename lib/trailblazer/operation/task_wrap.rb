module Trailblazer
  module Operation::Railway
    module TaskWrap
      def self.included(includer)
        includer.extend ClassMethods # ::__call__, ::inititalize_task_wraps!
        includer.extend DSL

        includer.initialize_task_wraps!
      end

      module ClassMethods
        def initialize_task_wraps!
          heritage.record :initialize_task_wraps!

          # The map of task_wrap per step/task. Note that it defaults to Wrap.initial_activity.
          # This gets extended at compile-time for particular tasks as the steps are created via the DSL.
          self["__static_task_wraps__"] = ::Hash.new(Circuit::Wrap.initial_activity)
        end

        # __call__ prepares `flow_options` and `static_wraps` for {TaskWrap::Runner}.
        def __call__(direction, options, flow_options={})
          options, flow_options, static_wraps = TaskWrap.arguments_for_call(self, direction, options, flow_options)

          super(direction, options, flow_options, static_wraps) # Railway::__call__
        end
      end

      def self.arguments_for_call(operation, direction, options, flow_options)
        activity      = operation["__activity__"]
        static_wraps  = operation["__static_task_wraps__"]

        # override:
        flow_options = flow_options.merge(
          runner:        Circuit::Wrap::Runner,
          introspection: Activity::Introspection.new(activity) # TODO: don't create this at run-time! TODO; don't do this here!
        )
        # reverse_merge:
                  # FIXME: this sucks, why do we even need to pass an empty runtime there?
        flow_options = { wrap_runtime: ::Hash.new([]) }.merge(flow_options)

        [ options, flow_options, static_wraps ]
      end

      module DSL
        # TODO: this override is hard to follow, we should have a pipeline circuit in DSL to add behavior.
        # @private
        def add_step!(*args)
          super.tap do |returned_hash|
            apply_wirings_from_runner_options!( returned_hash[:task], returned_hash[:runner_options] )
          end
        end # TODO: do this with a circuit :)

        # Extend the static wrap for a specific task, at compile time.
        def apply_wirings_from_runner_options!(task, alteration:nil, **)
          return unless alteration

          static_wrap = self["__static_task_wraps__"][task]

          # macro might want to apply changes to the static task_wrap (e.g. Inject)
          self["__static_task_wraps__"][task] = Activity.merge( static_wrap, alteration )
        end
      end
    end # TaskWrap
  end
end


# |-- Railway::Call "insert.exec_context"
