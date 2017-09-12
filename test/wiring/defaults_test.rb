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
      outputs:       Merge( ExceptionFromD => { role: :exception } ),
      connect_to:    Merge( exception: "End.myend" ),
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


# step :a
# fail :b, connect_to: { Circuit::Right => "End.success" }
# fail :c, connect_to: { Circuit::Right => "End.success" }

# @see https://github.com/trailblazer/trailblazer/issues/190#issuecomment-326992255
class WireDefaultsEarlyExitSuccessTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step :a
    fail :b, connect_to: Merge({ :success => "End.success" })
    fail :c, connect_to: Merge({ :success => "End.success" })

    def a(options, a_return:, **)
      options["a"] = 1

      a_return
    end

    def b(options, b_return:, **)
      options["b"] = options["a"]+1

      b_return
    end


    def c(options, c_return:, **)
      options["c"] = options["b"]+1

      c_return
    end
  end

  # a => true
  it { Create.({}, a_return: true).inspect("a", "b", "c").must_equal %{<Result:true [1, nil, nil] >} }
  # b => true
  it { Create.({}, a_return: false, b_return: true).inspect("a", "b", "c").must_equal %{<Result:true [1, 2, nil] >} }
  # c => true
  it { Create.({}, a_return: false, b_return: false, c_return: true).inspect("a", "b", "c").must_equal %{<Result:true [1, 2, 3] >} }
  # a => b => c => false
  it { Create.({}, a_return: false, b_return: false, c_return: false).inspect("a", "b", "c").must_equal %{<Result:false [1, 2, 3] >} }

  # require "trailblazer/developer"
  # it { Trailblazer::Developer::Client.push( operation: Create, name: "ushi" ) }
end
