require "test_helper"

class WireDefaultsTest < Minitest::Spec
  Circuit = Trailblazer::Circuit

  class C < Trailblazer::Operation
    # here, D has a step interface!
    D = ->(options, a:raise, b:raise, **) {
      options["D"] = [ a, b, options["c"] ]

      options["D_return"]
    }

    ExceptionFromD = Class.new(Circuit::Signal) # for steps, return value has to be subclass of Signal to be passed through as a signal and not a boolean.
    MyEnd = Class.new(Circuit::End)

    step ->(options, **) { options["a"] = 1 }, id: "a"
    step ->(options, **) { options["b"] = 2 }, id: "b"

    attach  MyEnd.new(:myend), id: "End.myend"

    # step provides defaults:
    step D,
      outputs:       Railway::DSL::Merge( ExceptionFromD => { role: :exception } ),
      connect_to:    Railway::DSL::Merge( exception: "End.myend" ),
      id:            "d"

    fail ->(options, **) { options["f"] = 4 }, id: "f"
    step ->(options, **) { options["c"] = 3 }, id: "c"
  end

  # normal flow as D sits on the Right track.
  it { C.({}, "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >} }
  # ends on MyEnd, without hitting fail.
  it { C.({}, "D_return" => C::ExceptionFromD).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >} } # todo: HOW TO CHECK End instance?
  it { C.({}, "D_return" => Circuit::Left).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >} } # todo: HOW TO CHECK End instance?
end
