require "test_helper"
# require "trailblazer/developer"

class WireTest < Minitest::Spec
  Circuit = Trailblazer::Circuit
  DSL = Trailblazer::Operation::Railway::DSL

  MyEnd          = Class.new(Circuit::End) # custom end event
  ExceptionFromD = Class.new               # custom signal

  D = ->((options, *args), *) do
    options["D"] = [ options["a"], options["b"], options["c"] ]

    signal = options["D_return"]
    [ signal, [ options, *args ] ]
  end

  #-
  class Create < Trailblazer::Operation
    step ->(options, **) { options["a"] = 1 }
    step ->(options, **) { options["b"] = 2 }, name: "b"

    step D,
      outputs: { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }, ExceptionFromD => { role: :exception } }, # any outputs and their polarization, generic.
      :exception => End("End.ExceptionFromD_happened")

    fail ->(options, **) { options["f"] = 4 }, id: "f"
    step ->(options, **) { options["c"] = 3 }, id: "c"
  end

  # myend ==> d
  it { Trailblazer::Operation::Inspect.(Create).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>#<Proc::21 (lambda)>,>b,End.myend,d,<<f,>c]} }

  # normal flow as D sits on the Right track.
  it do
    result = Create.({}, "D_return" => Circuit::Right)

    result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >}
    result.event.must_equal Create.outputs.keys[0]
  end

  # ends on MyEnd, without hitting fail.
  it do
    result = Create.({}, "D_return" => ExceptionFromD)

    result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >}
    result.event.must_equal Create.myend
  end

  # normal flow to left track.
  it do
    result = Create.({}, "D_return" => Circuit::Left)

    result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >}
    result.event.must_equal Create.outputs.keys[1]
  end

  # B is {Step}, we use ::attach and ::insert.
  class B < Trailblazer::Operation
    # here, D has a step interface!
    D = ->(options, a:raise, b:raise, **) {
      options["D"] = [ a, b, options["c"] ]

      options["D_return"]
    }

    ExceptionFromD = Class.new(Circuit::Signal) # for steps, return value has to be subclass of Signal to be passed through as a signal and not a boolean.
    def self.myend; @myend ||= MyEnd.new(:myend); end

    step ->(options, **) { options["a"] = 1 }, id: "a"
    step ->(options, **) { options["b"] = 2 }, id: "b"

    # attach  MyEnd.new(:myend), id: "End.myend"
    attach  myend, id: "End.myend"
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
  it do
    result = B.({}, "D_return" => Circuit::Right)

    result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >}
    result.event.must_equal B.outputs.keys[0]
  end

  # ends on MyEnd, without hitting fail.
  it do
    result = B.({}, "D_return" => B::ExceptionFromD)

    result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >}
    result.event.must_equal B.myend
  end

  # normal flow to left track.
  it do
    result = B.({}, "D_return" => Circuit::Left)

    result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >}
    result.event.must_equal B.outputs.keys[1]
  end


  class C < Trailblazer::Operation
    # here, D has a step interface!
    D = ->(options, a:raise, b:raise, **) {
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

# require "trailblazer/developer"
# it { puts xml = Trailblazer::Diagram::BPMN.to_xml( C["__activity__"], C["__sequence__"] )

#     File.write("berry.bpmn", xml)
#   }


  it { Trailblazer::Operation::Inspect.(C).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>a,>b,End.myend,>d,<<f,>c]} }

  # normal flow as D sits on the Right track.
  it { C.({}, "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >} }
  # ends on MyEnd, without hitting fail.
  it { C.({}, "D_return" => C::ExceptionFromD).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >} } # todo: HOW TO CHECK End instance?
  it { C.({}, "D_return" => Circuit::Left).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >} } # todo: HOW TO CHECK End instance?


  #- connect
  class E < Trailblazer::Operation
    step ->(options, **) { options["a"] = 1 }, id: "a"
    step ->(options, b_return:, **) { options["b"] = 2; b_return }, id: "b"
    fail ->(options, f_return:, **) { options["f"] = 4; f_return }, id: "f"
    connect "f", edge: Circuit::Right, target: "End.success"

    step ->(options, **) { options["c"] = 3 }, id: "c"
  end

  it { E.({}, "b_return" => true).inspect("a", "b", "c", "f").must_equal %{<Result:true [1, 2, 3, nil] >} }
  # go to fail, but normal fail behavior.
  it { E.({}, "b_return" => false,
              "f_return" => false).inspect("a", "b", "c", "f").must_equal %{<Result:false [1, 2, nil, 4] >} }
  # go to fail and back to right track.
  it { E.({}, "b_return" => false,
              "f_return" => Circuit::Right).inspect("a", "b", "c", "f").must_equal %{<Result:true [1, 2, 3, 4] >} }

  # it { puts xml = Trailblazer::Diagram::BPMN.to_xml( E["__activity__"], E["__sequence__"] )
  #   File.write("berry2.bpmn", xml)
  # }


  #- add a node before End.failure and connect all other before that.
  class F < Trailblazer::Operation
    # 1
    step ->(options, **) { options["a"] = 1 }, id: "a"

    # 4
    # our success "end":
    step ->(options, **) { options["z"] = 2 }, id: "z"

    # 2
    pass ->(options, a:, **) { options["b"] = [a, options["c"], options["z"]].inspect },
      insert_before: "z", id: "b" #, connect_to: Right => Z #FIXME: we also need to change connect_to, e.g. connect_to: Merge( success: "z" )

    # 3
    pass ->(options, a:, b:, **) { options["c"] = [a,b, options["z"], 1] },
      insert_before: "z", id: "c"


    # fail ->(options, f_return:, **) { options["f"] = 4; f_return }, id: "f"
    # connect "f", edge: Circuit::Right, target: "End.success"

    # step ->(options, **) { options["c"] = 3 }, id: "c"
  end

  it { skip "implement" }
  # it { pp F['__sequence__'].to_a }
  # it { F.({}, "b_return" => false,
  #                                 ).inspect("a", "b", "c", "z").must_equal %{<Result:true [1, "[1, nil, nil]", [1, "[1, nil, nil]", nil], 2] >} }
  # it {
  #   puts xml = Trailblazer::Diagram::BPMN.to_xml( F["__activity__"], F["__sequence__"] )
  #   File.write("berry3.bpmn", xml)
  # }
end

class WireExceptionTest < Minitest::Spec
  # role in :outputs can't be connected because not in :connect_to.
  it do
    exception = assert_raises do
      class Create < Trailblazer::Operation
        step :a, outputs: { "some" => { role: :success } }, connect_to: { :not_existent => "End.success" }
      end
    end

    exception.message.must_equal %{Couldn't map output role :success for {:not_existent=>"End.success"}}
  end
end
