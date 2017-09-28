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
          self["__static_task_wraps__"] = ::Hash.new(Activity::Wrap.initial_activity)
        end

        # __call__ prepares `flow_options` and `static_wraps` for {TaskWrap::Runner}.
        def __call__(args, **circuit_args)
          args, _circuit_args = TaskWrap.arguments_for_call(self, args)

          super( args, _circuit_args.merge(circuit_args) )
        end
      end

      def self.arguments_for_call(operation, (options, flow_options))
        activity    = operation["__activity__"]
        wrap_static = operation["__static_task_wraps__"]

        # override:
        flow_options = flow_options.merge(
          introspection: Activity::Introspection.new(activity) # TODO: don't create this at run-time! TODO; don't do this here!
        )
        # reverse_merge:

        circuit_args = {
          runner:        Activity::Wrap::Runner,
                  # FIXME: this sucks, why do we even need to pass an empty runtime there?
          wrap_runtime: ::Hash.new([]),
          wrap_static:  wrap_static,
        }

        [ [ options, flow_options ], circuit_args ]
      end

      module DSL
        # TODO: this override is hard to follow, we should have a pipeline circuit in DSL to add behavior.
        # @private
        def _element(*args)
          super.tap do |runner_options:nil, task:raise, **ignored|
            runner_options and apply_wirings_from_runner_options!( task, runner_options )
          end
        end # TODO: do this with a circuit :)

        # Extend the static wrap for a specific task, at compile time.
        def apply_wirings_from_runner_options!(task, alteration:raise, **ignored)
          static_wrap = self["__static_task_wraps__"][task]

          # macro might want to apply changes to the static task_wrap (e.g. Inject)
          self["__static_task_wraps__"][task] = Activity.merge( static_wrap, alteration )
        end
      end
    end # TaskWrap
  end
end


# |-- Railway::Call "insert.exec_context"
