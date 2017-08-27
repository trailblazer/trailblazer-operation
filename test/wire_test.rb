require "test_helper"

class WireTest < Minitest::Spec
  Circuit = Trailblazer::Circuit
  DSL = Trailblazer::Operation::Railway::DSL
  Insert = Trailblazer::Operation::Railway::Insert

  MyEnd = Class.new(Circuit::End)
  ExceptionFromD = Class.new

  D = ->(signal, options, flow_options, *args) do
    options["D"] = [ options["a"], options["b"], options["c"] ]

    signal = options["D_return"]
    [ signal, options, flow_options, *args ]
  end

  #- manual via ::graph API
  class Create < Trailblazer::Operation
    step ->(options, **) { options["a"] = 1 }
    step ->(options, **) { options["b"] = 2 }, name: "b"

    # step provides insert_before, outputs, node_data

    add_element! [ [:attach!, target: [MyEnd.new(:myend), {id: _id="End.myend"}], edge: [Circuit::Left, {}], source: "Start.default"] ], id: _id

    add_element! Insert.insertion_wirings_for( task: D,
          insert_before: "End.success",
          outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }, ExceptionFromD => { role: :exception } }, # any outputs and their polarization, generic.
          connect_to:      { success: "End.success", failure: "End.failure", exception: "End.myend" }, # where do my task's outputs go?,
          node_data: { id: _id="d" }), id: _id #, before: :bla

    fail ->(options, **) { options["f"] = 4 }, id: "f"
    step ->(options, **) { options["c"] = 3 }, id: "c"

    # element MyMacro(), insert_before: "End.success", connect_to: { success: "End.success", failure: "End.myend" }
    # element MyMacro(), insert_before: "End.success", connect_to: { success: "End.success", failure: "End.myend" }, id: "MyMacro.2"
  end

  # myend ==> d
  it { Trailblazer::Operation::Inspect.(Create).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>#<Proc::20 (lambda)>,>b,End.myend,d,<<f,>c]} }

  # normal flow as D sits on the Right track.
  it { Create.({}, "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >} }
  # ends on MyEnd, without hitting fail.
  it { Create.({}, "D_return" => ExceptionFromD).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >} } # todo: HOW TO CHECK End instance?
  it { Create.({}, "D_return" => Circuit::Left).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >} } # todo: HOW TO CHECK End instance?

  class B < Trailblazer::Operation
    extend Railway::Attach::DSL
    extend Railway::Insert::DSL

    # here, D has a step interface!
    D = ->(options, a:, b:, **) {
      options["D"] = [ a, b, options["c"] ]

      options["D_return"]
    }

    ExceptionFromD = Class.new(Circuit::Signal) # for steps, return value has to be subclass of Signal to be passed through as a signal and not a boolean.

    step ->(options, **) { options["a"] = 1 }, id: "a"
    step ->(options, **) { options["b"] = 2 }, id: "b"

    attach  MyEnd.new(:myend), id: "End.myend"
    insert D,
      insert_before: "End.success",
      outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }, ExceptionFromD => { role: :exception } }, # any outputs and their polarization, generic.
      connect_to:    { success: "End.success", failure: "End.failure", exception: "End.myend" },
      id:            "d"

    fail ->(options, **) { options["f"] = 4 }, id: "f"
    step ->(options, **) { options["c"] = 3 }, id: "c"
  end

  it { Trailblazer::Operation::Inspect.(B).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>a,>b,End.myend,d,<<f,>c]} }

  # normal flow as D sits on the Right track.
  it { B.({}, "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >} }
  # ends on MyEnd, without hitting fail.
  it { B.({}, "D_return" => B::ExceptionFromD).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >} } # todo: HOW TO CHECK End instance?
  it { B.({}, "D_return" => Circuit::Left).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >} } # todo: HOW TO CHECK End instance?


  class C < Trailblazer::Operation
    extend Railway::Attach::DSL
    extend Railway::Insert::DSL

    # here, D has a step interface!
    D = ->(options, a:, b:, **) {
      options["D"] = [ a, b, options["c"] ]

      options["D_return"]
    }

    ExceptionFromD = Class.new(Circuit::Signal) # for steps, return value has to be subclass of Signal to be passed through as a signal and not a boolean.

    step ->(options, **) { options["a"] = 1 }, id: "a"
    step ->(options, **) { options["b"] = 2 }, id: "b"

    attach  MyEnd.new(:myend), id: "End.myend"
    step D,
      outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }, ExceptionFromD => { role: :exception } }, # any outputs and their polarization, generic.
      connect_to:    { success: "End.success", failure: "End.failure", exception: "End.myend" },
      id:            "d"

    fail ->(options, **) { options["f"] = 4 }, id: "f"
    step ->(options, **) { options["c"] = 3 }, id: "c"
  end

  it { Trailblazer::Operation::Inspect.(C).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>a,>b,End.myend,>d,<<f,>c]} }

  # normal flow as D sits on the Right track.
  it { C.({}, "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >} }
  # ends on MyEnd, without hitting fail.
  it { C.({}, "D_return" => C::ExceptionFromD).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >} } # todo: HOW TO CHECK End instance?
  it { C.({}, "D_return" => Circuit::Left).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >} } # todo: HOW TO CHECK End instance?
end
