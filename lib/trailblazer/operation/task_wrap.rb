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

        # options is a Skill already.
        # __call__ injects all necessary parameters into flow_options
        # so we can use task wraps per task, do tracing, etc.
        def __call__(direction, options, flow_options={}) # FIXME: direction
          options, flow_options = TaskWrap.arguments_for_call(self, direction, options, flow_options)

          super(direction, options, flow_options) # Railway::__call__
        end
      end

      def self.arguments_for_call(operation, direction, options, flow_options)
        activity     = operation["__activity__"]

        # TODO: we can probably save a lot of time here by using constants.
        # TODO: this sucks as we merge the wrap_static, otherwise a nested op can override and removes all followin wraps. we have to use a Context for this.
        wrap_static  = operation["__static_task_wraps__"] # .merge( flow_options[:wrap_static].instance_variable_get(:@map) || {} ) )

        # override:
        flow_options = flow_options.merge(
          runner:      Circuit::Wrap::Runner,
          wrap_static: wrap_static,
          # debug:       activity.circuit.instance_variable_get(:@name)
          introspection:       Activity::Introspection.new(activity) # TODO: don't create this at run-time! TODO; don't do this here!
        )
        # reverse_merge:
                  # FIXME: this sucks, why do we even need to pass an empty runtime there?
        flow_options = { wrap_runtime: ::Hash.new([]) }.merge(flow_options)

        [ options, flow_options ]
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
