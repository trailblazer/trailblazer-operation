require "test_helper"

class PublicCallMonkeypatchingTest < Minitest::Spec
  #@ test overriding {Operation.call_with_public_interface}
  #@
  module AfterCall
    def self.add_task_name(wrap_ctx, original_args)
      (ctx, _flow_options), circuit_options = original_args

      activity  = circuit_options[:activity] # currently running Activity.
      task      = wrap_ctx[:task]            # the current "step".
      task_id   = Trailblazer::Activity::Introspect.Nodes(activity, task: task).id

      ctx[:seq] << task_id

      return wrap_ctx, original_args # yay to mutable state. not.
    end
  end

  it "overrides {call_with_public_interface} and allows injecting {circuit_options} and {flow_options} from the override" do
    TaskWrapExtension = Trailblazer::Activity::TaskWrap::Extension(
      [AfterCall.method(:add_task_name), id: "my.add_1", append: "task_wrap.call_task"]
    )

    module OperationExtensions
      def call_with_public_interface(ctx, flow_options, **circuit_options)
        super(
          ctx,
          flow_options.merge({}),
          **circuit_options.merge(
            wrap_runtime: Hash.new(TaskWrapExtension),
            runner: Trailblazer::Activity::TaskWrap::Runner
          )
        )
      end
    end

    operation = Class.new(Trailblazer::Operation) do
      step :a

      include Trailblazer::Activity::Testing.def_steps(:a)
    end
    operation.extend OperationExtensions # monkey-patch the "global" Operation.


    # circuit interface invocation using call
    result = operation.call(
      seq: []
    )

    assert_equal result.success?, true
    assert_equal result[:seq], ["Start.default", :a, :a, "End.success", nil] # {nil} because we don't have an ID for the actual operation.
  end
end

class FlowOptionsMonekypatching < Minitest::Spec
  module App
    FLOW_OPTIONS = {
      context_options: {
        aliases: { "contract.default": :contract },
        container_class: Trailblazer::Context::Container::WithAliases,
      }
    }

    module OperationExtensions
      def call_with_public_interface(ctx, flow_options, **circuit_options)
        super(
          ctx,
          flow_options.merge(App::FLOW_OPTIONS),
          **circuit_options
        )
      end
    end
  end

  it do
    operation = Class.new(Trailblazer::Operation) do
      step :a

      def a(ctx, contract:, **)
        ctx[:seq] << contract
      end
    end
    operation.extend App::OperationExtensions # monkey-patch the "global" Operation.


    # circuit interface invocation using call
    result = operation.call(
      seq: [],
      :"contract.default" => Object,
    )

    assert_equal result.success?, true
    assert_equal result[:seq].inspect, %([Object])
  end
end
