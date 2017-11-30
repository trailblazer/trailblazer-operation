require "test_helper"

class TraceTest < Minitest::Spec
  MyNested = ->(*args) do
    B.__call__(*args)

    [ Trailblazer::Circuit::Right, *args ]
  end

  class Create < Trailblazer::Operation
    step ->(options, a_return:, **) { options[:a] = a_return }, id: "Create.task.a"
    step task: MyNested, id: "MyNested"
    step ->(options, **) { options[:c] = true }, id: "Create.task.c"
    step ->(options, params:, **) { params.any? }, id: "Create.task.params"
  end
  # raise Create["__task_wraps__"].inspect

  class B < Trailblazer::Operation
    step ->(options, **) { options[:b] = true }, id: "B.task.b"
    step ->(options, **) { options[:e] = true }, id: "B.task.e"
  end

  it "allows using low-level Activity::Trace" do
    operation = ->(*args) { puts "@@@@@ #{args.last.inspect}"; Create.__call__(*args) }

    stack, _ = Trailblazer::Activity::Trace.(
      operation,
      options={ a_return: true, "params" => {} },
    )

# p stack

    puts output = Trailblazer::Activity::Trace::Present.tree(stack)

    output.gsub(/0x\w+/, "").gsub(/@.+_test/, "").must_equal %{|-- Start.default
|-- Create.task.a
|-- #<Proc:.rb:4 (lambda)>
|   |-- Start.default
|   |-- B.task.b
|   |-- B.task.e
|   |-- End.success
|   `-- #<Proc:.rb:4 (lambda)>
|-- Create.task.c
|-- Create.task.params
`-- End.failure}
  end

  it "Operation::trace" do
    result = Create.trace({ x: 1 }, options={ a_return: true })
    result.wtf?.gsub(/0x\w+/, "").gsub(/@.+_test/, "").must_equal %{|-- Start.default
|-- Create.task.a
|-- #<Proc:.rb:4 (lambda)>
|   |-- Start.default
|   |-- B.task.b
|   |-- B.task.e
|   |-- End.success
|   `-- #<Proc:.rb:4 (lambda)>
|-- Create.task.c
|-- Create.task.params
`-- End.success}
  end
end
