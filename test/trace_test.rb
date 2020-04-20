require "test_helper"

class TraceTest < Minitest::Spec
  class B < Trailblazer::Operation
    step ->(options, **) { options[:b] = true }, id: "B.task.b"
    step ->(options, **) { options[:e] = true }, id: "B.task.e"
  end

  class Create < Trailblazer::Operation
    step ->(options, a_return:, **) { options[:a] = a_return }, id: "Create.task.a"
    step({task: B, id: "MyNested"}, B.to_h[:outputs][0] => Track(:success))
    step ->(options, **) { options[:c] = true }, id: "Create.task.c"
    step ->(_options, params:, **) { params.any? }, id: "Create.task.params"
  end
  # raise Create["__task_wraps__"].inspect

  it "allows using low-level Operation::Trace" do
    result = Trailblazer::Operation::Trace.(
      Create,
      { a_return: true, params: {} },
    )

    output = result.wtf

    output.gsub(/0x\w+/, "").gsub(/@.+_test/, "").must_equal %{`-- TraceTest::Create
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

  it "Operation::trace" do
    result = Create.trace(params: {x: 1}, a_return: true)
    result.wtf.gsub(/0x\w+/, "").gsub(/@.+_test/, "").must_equal %{`-- TraceTest::Create
    |-- Start.default
    |-- Create.task.a
    |-- MyNested
    |   |-- Start.default
    |   |-- B.task.b
    |   |-- B.task.e
    |   `-- End.success
    |-- Create.task.c
    |-- Create.task.params
    `-- End.success}
  end
end
