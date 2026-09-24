require "test_helper"

# Tests around {Operation.call}.
class OperationTest < Minitest::Spec
  def assert_result(result, boolean, **ctx)
    assert_equal result.success?, boolean
    assert_equal result.to_h, ctx
  end

  it "empty Operation, circuit interface" do
    assert_run Class.new(Trailblazer::Operation), terminus: :success, seq: []
  end

  it "empty Operation, public interface" do
    my_result = Class.new(Trailblazer::Operation).()

    assert_result my_result, true
  end


  class MyOperation <Trailblazer::Operation
    step :a
    step :b

    include T.def_steps(:a, :b)
  end

  it "Operation.call" do
    assert_run MyOperation, seq: [:a, :b], terminus: :success # circuit-interface
    assert_result MyOperation.(seq: [1]), true, seq: [1, :a, :b]
  end

  it "Operation.call with positional hash" do

  end

  it "Operation provides Wiring API" do
    raise "show me"
  end

  it "Operation.wtf?" do
    result = nil
    output, _ = capture_io do
      result = MyOperation.wtf?(seq: [1])
    end

    assert_result result, true, seq: [1, :a, :b]
    puts output
    assert_equal output, %(\e[30mOperationTest::MyOperation\e[0m
`-- \e[30mtask_wrap.call_task\e[0m
    |-- \e[32ma\e[0m
    |   `-- \e[32mtask_wrap.call_task\e[0m
    |       |-- \e[30minvoke_provider\e[0m
    |       |-- \e[30mis_signal?\e[0m
    |       `-- \e[32mcompute_binary_signal\e[0m
    |-- \e[32mb\e[0m
    |   `-- \e[32mtask_wrap.call_task\e[0m
    |       |-- \e[30minvoke_provider\e[0m
    |       |-- \e[30mis_signal?\e[0m
    |       `-- \e[32mcompute_binary_signal\e[0m
    `-- \e[30mEnd.success\e[0m
        `-- \e[30mtask_wrap.call_task\e[0m
)
  end

  it "Operation.wtf? with raise" do
    result, output = nil

    output, _ = capture_io do
      assert_raises KeyError do
        result = MyOperation.wtf?(seq: [1], a: Class.new(Trailblazer::Activity::Signal))
      end
    end

    assert_equal result, nil
    assert_equal output, %(\e[37m...OperationTest::MyOperation\e[0m
`-- \e[37m...wtf_top_canonical\e[0m
    `-- \e[37m...task_wrap.call_task\e[0m
        `-- \e[30m...a\e[0m
            `-- \e[30m...task_wrap.call_task\e[0m
                |-- \e[30m...invoke_provider\e[0m
                `-- \e[30m...is_signal?\e[0m
)
  end

  it "Operation.wtf? can show all steps " do
    raise "implement me"
  end

#   it "canonical invoke #__ allows a second argument and accepts invoke options" do
#     operation_class = Trailblazer::Operation
#     signal, result = nil

#     stdout, _ = capture_io do
#       ctx, _, signal = operation_class.__(operation_class, {params: {id: 1}}, **Trailblazer::Developer::Wtf.options_for_canonical_invoke)
#     end

#     assert_equal signal.to_h[:semantic], :success
#     assert_equal CU.strip(stdout), %(Trailblazer::Operation
# |-- \e[32mStart.default\e[0m
# `-- End.success\n)
#   end

  # it "we can use the circuit-interface and inject options like {:runner}" do
  #   # Internally, TaskWrap::Runner.call_task invokes the circuit-interface.
  #   ctx, _, signal = Trailblazer::Activity::TaskWrap.invoke(Trailblazer::Operation, {id: 1})

  #   assert_equal signal.to_h[:semantic], :success
  #   assert_equal ctx.class, Hash # because canonical invoke is not called.
  # end


  # it "Operation.call accepts block matcher interface" do
  #   my_operation = Class.new(Trailblazer::Operation) do
  #     step :model
  #     include T.def_steps(:model)
  #   end

  #   @render = nil

  #   result = my_operation.(seq: []) do
  #     success { |ctx, seq:, **| @render = "success! #{seq}" }
  #     failure { |ctx, seq:, **| @render = "failure! #{seq}" }
  #   end

  #   assert_equal @render, %(success! [:model])
  # end


  it "{Operation.call} invokes with the taskWrap" do
    skip "check me"
    def add_1(wrap_ctx, flow_options, _)
      ctx = wrap_ctx[:application_ctx]
      ctx[:seq] << 1

      return wrap_ctx, flow_options
    end

    add_1_method = method(:add_1)

    operation = Class.new(Trailblazer::Operation) do
      include T.def_steps(:model)

      step :model,
        Extension() => Trailblazer::Activity::TaskWrap.Extension(
          [add_1_method, prepend: "task_wrap.call_task", id: "user.add_1"]
        )
    end

    # normal operation invocation
    assert_call operation, seq: "[1, :model]"

    result = nil
    # with tracing
    stdout, _ = capture_io do
      result = operation.wtf?(seq: [])
    end

    assert_equal CU.strip(stdout), %(#<Class:0x>
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
)
    assert_equal CU.inspect(result.to_h), %({:seq=>[1, :model]})
    assert_equal result.terminus.to_h[:semantic], :success

  # with circuit-interface and {:wrap_runtime}.
    my_runtime_extension = Trailblazer::Activity::TaskWrap::Extension(
      [add_1_method, id: "my.add_1", append: "task_wrap.call_task"]
    )

    # circuit interface invocation using call
    ctx, _, signal = operation.(
      {seq: []},
      {},
      {
        wrap_runtime: Hash.new(my_runtime_extension),
        runner: Trailblazer::Activity::TaskWrap::Runner
      }
    )

    assert_equal signal.to_h[:semantic], :success
    assert_equal CU.inspect(ctx), %({:seq=>[1, 1, :model, 1, 1]}) # {Start.default} is a step, too :D
  end

  it "{Operation.call} works with operations that expose public {:normalizer_extensions}" do
    skip "implement me!"
    operation = Class.new(Trailblazer::Operation) do
      # This usually happens in extensions such as {trailblazer-dependency}.
      def self.my_normalizer_ext(ctx, flow_options, _, id:, **)
        my_task_wrap_ext = Trailblazer::Activity::TaskWrap::Extension(
          [
            ->(wrap_ctx, flow_options, _) {
              wrap_ctx[:application_ctx][:tw] = "hello from taskWrap #{id.inspect}"

              return wrap_ctx, flow_options
            },
            id: "xxx",
            prepend: nil
          ]
        )

        ctx = ctx.merge(Trailblazer::Activity::Railway.Extension() => my_task_wrap_ext)

        return ctx, flow_options
      end

      my_normalizer_ext = Trailblazer::Activity::DSL::Linear::Normalizer.Extension(method(:my_normalizer_ext))

      @state.update!(:fields) do |fields|
        exts = fields[:normalizer_extensions] # [call_task]
        exts = exts + [my_normalizer_ext]
        fields.merge(normalizer_extensions: exts)
      end
    end

    # We can inject options when using canonical invoke.
    ctx, flow_options, signal = Trailblazer::Operation.__(operation, {}, normalizer_options: {id: "tw ID xxx"})
    assert_equal CU.inspect(ctx.to_h), %({:tw=>\"hello from taskWrap \\\"tw ID xxx\\\"\"})

    # ...with public interface, that's not possible.
    assert_raises ArgumentError do
      result = operation.({}) # ArgumentError: missing keyword: :id
      # assert_equal CU.inspect(result.to_h), %({:tw=>\"hello from taskWrap nil\"})
    end
  end
end
