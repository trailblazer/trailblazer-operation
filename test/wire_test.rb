require "test_helper"

class WireTest < Minitest::Spec
  Circuit = Trailblazer::Circuit

  #- manual via ::graph API
  class Create < Trailblazer::Operation
    def self.graph
      self["__activity__"].graph
    end

    MyEnd = Class.new(Circuit::End)

    step ->(options, **) { options["a"] = 1 }
    step ->(options, **) { options["b"] = 1 }, name: "b"
    graph.attach! target: [MyEnd.new(:myend), id: "End.myend"], edge: [Circuit::Left, {}], source: "Start.default"
    # graph.connect! target: [B, id: :b], edge: []
    step ->(options, **) { options["c"] = 3 }


    element task: :d,
      insert_before: "End.success",
      outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure } }, # any outputs and their polarization, generic.
      connect_to:      { success: "End.success", failure: "End.myend" }, # where do my task's outputs go?,
      task_meta_data: { id: "d" }
  end
end
