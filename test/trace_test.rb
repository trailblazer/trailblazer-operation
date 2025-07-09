require "test_helper"

class TraceTest < Minitest::Spec
  class B < Trailblazer::Operation
    step ->(options, **) { options[:b] = true }, id: "B.task.b"
    step ->(options, **) { options[:e] = true }, id: "B.task.e"
  end

  class Create < Trailblazer::Operation
    step ->(options, a_return:, **) { options[:a] = a_return }, id: "Create.task.a"
    step Subprocess(B), id: "MyNested"
    step ->(options, **) { options[:c] = true }, id: "Create.task.c"
    step ->(_options, params:, **) { params.any? }, id: "Create.task.params"
  end

  it "allows using low-level Operation::Trace" do
    signal, (ctx, flow_options) = Trailblazer::Operation.__(
      Create,
      {a_return: true, params: {}},
      **Trailblazer::Developer::Trace.options_for_canonical_invoke()
    )

    stack = flow_options[:stack]

    output = Trailblazer::Developer::Trace::Present.(stack)

    assert_equal output.gsub(/0x\w+/, "").gsub(/@.+_test/, ""), %{TraceTest::Create
|-- Start.default
|-- Create.task.a
|-- MyNested
|   |-- Start.default
|   |-- B.task.b
|   |-- B.task.e
|   `-- End.success
|-- Create.task.c
|-- Create.task.params
`-- End.failure}
  end

  it "Operation.wtf?" do
    result = nil
    output, = capture_io do
      result = Create.wtf?(params: {x: 1}, a_return: true)
    end

    assert_equal output.gsub(/0x\w+/, "").gsub(/@.+_test/, ""), %{TraceTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mCreate.task.a\e[0m
|-- MyNested
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32mB.task.b\e[0m
|   |-- \e[32mB.task.e\e[0m
|   `-- End.success
|-- \e[32mCreate.task.c\e[0m
|-- \e[32mCreate.task.params\e[0m
`-- End.success
}

    result.success?.must_equal true
    result[:a_return].must_equal true
    assert_equal CU.inspect(result[:params]), %({:x=>1})
  end
end
