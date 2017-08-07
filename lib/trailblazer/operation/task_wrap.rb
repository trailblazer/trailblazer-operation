module Trailblazer
  module Operation::Railway
    module TaskWrap
      def self.included(includer)
        includer.extend ClassMethods # ::call, ::inititalize_pipetree!
        includer.extend DSL

        includer.initialize_task_wraps!
      end

      module ClassMethods
        def initialize_task_wraps!
          heritage.record :initialize_task_wraps!

          self["__task_wraps__"] = {}
        end

        # options is a Skill already.
        # __call__ injects all necessary parameters into flow_options
        # so we can use task wraps per task, do tracing, etc.
        def __call__(direction, options, flow_options={}) # FIXME: direction
          activity     = self["__activity__"]

          options, flow_options = TaskWrap.arguments_for_call(self, direction, options, flow_options)

          super(direction, options, flow_options) # Railway::__call__
        end
      end

      def self.arguments_for_call(operation, direction, options, flow_options)
        activity     = operation["__activity__"]

        # TODO: we can probably save a lot of time here by using constants.
        wrap_static  = Circuit::Wrap::Alterations.new( map: operation["__task_wraps__"] )
        wrap_runtime = Circuit::Wrap::Alterations.new

        # override:
        flow_options = flow_options.merge(
          runner:      Circuit::Wrap::Runner,
          wrap_static: wrap_static,
          # debug:       activity.circuit.instance_variable_get(:@name)
          debug:       activity.instance_variable_get(:@name)
        )
        # reverse_merge:
        flow_options = { wrap_runtime: wrap_runtime }.merge(flow_options)

        [ options, flow_options ]
      end

      module DSL
        # TODO: this override is hard to follow, we should have a pipeline circuit in DSL to add behavior.
        # @private
        def add_step!(*args)
          super.tap do |returned_hash|
            save_task_wrap_from_runner_options!( returned_hash[:task], returned_hash[:runner_options] )
          end
        end # TODO: do this with a circuit :)

        def save_task_wrap_from_runner_options!(task, alteration:nil, **)
          task_wrap = Circuit::Wrap::Activity # default.
          task_wrap = alteration.(task_wrap) if alteration # macro might want to apply changes to the static task_wrap (e.g. Inject)

          self["__task_wraps__"][task] = [ Proc.new{task_wrap} ]
        end
      end
    end # TaskWrap
  end
end


# |-- Railway::Call "insert.exec_context"
