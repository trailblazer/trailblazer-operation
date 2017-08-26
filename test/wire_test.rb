require "test_helper"

class WireTest < Minitest::Spec
  Circuit = Trailblazer::Circuit
  DSL = Trailblazer::Operation::Railway::DSL

  MyEnd = Class.new(Circuit::End)

  #- manual via ::graph API
  class Create < Trailblazer::Operation
    def self.graph
      self["__activity__"].graph
    end



    step ->(options, **) { options["a"] = 1 }
    step ->(options, **) { options["b"] = 1 }, name: "b"
    step ->(options, **) { options["c"] = 3 }, name: :c

    # step provides insert_before, outputs, node_data

    #graph.attach! target: [MyEnd.new(:myend), id: "End.myend"], edge: [Circuit::Left, {}], source: "Start.default"
    # graph.connect! target: [B, id: :b], edge: []

    insert! [ [:attach!, target: [MyEnd.new(:myend), {id: _id="End.myend"}], edge: [Circuit::Left, {}], source: "Start.default"] ], id: _id

    insert! insertion_wirings_for( task: :d,
          insert_before: "End.success",
          outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure } }, # any outputs and their polarization, generic.
          connect_to:      { success: "End.success", failure: "End.myend" }, # where do my task's outputs go?,
          node_data: { id: _id="d" }), id: _id #, before: :bla

    # element MyMacro(), insert_before: "End.success", connect_to: { success: "End.success", failure: "End.myend" }
    # element MyMacro(), insert_before: "End.success", connect_to: { success: "End.success", failure: "End.myend" }, id: "MyMacro.2"
  end

  # myend ==> d
  it { Trailblazer::Operation::Inspect.(Create).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>#<Proc::15 (lambda)>,>b,>c,End.myend,d]} }

  class B < Trailblazer::Operation
    insert! [ [:attach!, target: [MyEnd.new(:myend), {id: _id="End.myend"}], edge: [Circuit::Left, {}], source: "Start.default"] ], id: _id
  end

  puts Trailblazer::Operation::Inspect.(Create)#.gsub(/0x.+?step_test.rb/, "").must_equal %{}
end
