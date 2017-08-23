require "test_helper"

class TraceTest < Minitest::Spec
  Circuit = Trailblazer::Circuit

  MyNested = ->(direction, options, flow_options) do
    B.__call__(B.instance_variable_get(:@start), options, flow_options )

    [ direction, options, flow_options ]
  end

  class Create < Trailblazer::Operation
    step ->(options, **) { options[:a] = true }, name: "Create.task.a"
    step [ MyNested, {} ],                       name: "MyNested"
    step ->(options, **) { options[:c] = true }, name: "Create.task.c"
  end
  # raise Create["__task_wraps__"].inspect

  class B < Trailblazer::Operation
    step ->(options, **) { options[:b] = true }, name: "B.task.b"
    step ->(options, **) { options[:e] = true }, name: "B.task.e"
  end

  it do
    operation = ->(*args) { Create.__call__(*args) }

    stack, _ = Trailblazer::Circuit::Trace.(
      operation,
      nil,
      options={},
    )

    puts output = Circuit::Trace::Present.tree(stack)

    output.gsub(/0x\w+/, "").gsub(/@.+_test/, "").must_equal %{|-- Start.default
|-- Create.task.a
|-- #<Proc:.rb:6 (lambda)>
|   |-- Start.default
|   |-- B.task.b
|   |-- B.task.e
|   |-- End.success
|   `-- #<Proc:.rb:6 (lambda)>
|-- Create.task.c
`-- End.success}
  end

  it "Operation::trace" do
    result = Create.trace(options={})
    result.wtf?.gsub(/0x\w+/, "").gsub(/@.+_test/, "").must_equal %{|-- Start.default
|-- Create.task.a
|-- #<Proc:.rb:6 (lambda)>
|   |-- Start.default
|   |-- B.task.b
|   |-- B.task.e
|   |-- End.success
|   `-- #<Proc:.rb:6 (lambda)>
|-- Create.task.c
`-- End.success}
  end
end
