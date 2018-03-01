require "test_helper"

# class WireDefaultsTest < Minitest::Spec
  # class C < Trailblazer::Operation
  #   # here, D has a step interface!
  #   D = ->(options, a:raise, b:raise, **) {
  #     options["D"] = [ a, b, options["c"] ]

  #     options["D_return"]
  #   }

  #   ExceptionFromD = Class.new(Circuit::Signal) # for steps, return value has to be subclass of Signal to be passed through as a signal and not a boolean.
  #   MyEnd = Class.new(Circuit::End)

  #   step ->(options, **) { options["a"] = 1 }, id: "a"
  #   step ->(options, **) { options["b"] = 2 }, id: "b"

  #   attach  MyEnd.new(:myend), id: "End.myend"

  #   # step provides defaults:
  #   step D,
  #     outputs:       Merge( ExceptionFromD => { role: :exception } ),
  #     connect_to:    Merge( exception: "End.myend" ),
  #     id:            "d"

  #   fail ->(options, **) { options["f"] = 4 }, id: "f"
  #   step ->(options, **) { options["c"] = 3 }, id: "c"
  # end

#   # normal flow as D sits on the Right track.
#   it { C.( "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >} }
#   # ends on MyEnd, without hitting fail.
#   it { C.( "D_return" => C::ExceptionFromD).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >} } # todo: HOW TO CHECK End instance?
#   it { C.( "D_return" => Circuit::Left).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >} } # todo: HOW TO CHECK End instance?
#   it do
#       step1 = C["__sequence__"][0].instructions[0].last[:node][0]
#       step2 = C["__sequence__"][1].instructions[0].last[:node][0]
#       step3 = C["__sequence__"][3].instructions[0].last[:node][0] # D
#       step4 = C["__sequence__"][4].instructions[0].last[:node][0]
#       step5 = C["__sequence__"][5].instructions[0].last[:node][0]

#       require "trailblazer/activity/schema"

#       Output = Trailblazer::Activity::Schema::Output

#       steps = [
#         [ [:success], step1, [Output.new(Circuit::Right, :success), Output.new(Circuit::Left, :failure)] ],
#         [ [:success], step2, [Output.new(Circuit::Right, :success), Output.new(Circuit::Left, :failure)] ],

#         [ [:success], step3, [Output.new(Circuit::Right, :success), Output.new(Circuit::Left, :failure), Output.new(C::ExceptionFromD, :exception)] ],
#         [ [:exception], C::MyEnd.new(:myend), [] ],

#         [ [:failure], step4, [Output.new(Circuit::Right, :failure), Output.new(Circuit::Left, :failure)] ],
#         [ [:success], step5, [Output.new(Circuit::Right, :success), Output.new(Circuit::Left, :failure)] ],
#       ]

#       ends = [
#         [ [:success], Trailblazer::Operation::Railway::End::Success.new(:success), [] ],
#         [ [:failure], Trailblazer::Operation::Railway::End::Failure.new(:failure), [] ],
#       ]


#       graph = Trailblazer::Activity::Schema.bla(steps + ends)
#       circuit = Trailblazer::Activity.new(graph)
#       # pp schema

#       C["__activity__"] = circuit # this is so wrong
#       C.( "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >}

#     end
# end

# # step :a
# # fail :b, connect_to: { Circuit::Right => "End.success" }
# # fail :c, connect_to: { Circuit::Right => "End.success" }

# Connect failure steps to right track, allowing to append steps after.
# @see https://github.com/trailblazer/trailblazer/issues/190#issuecomment-326992255
class WireDefaultsEarlyExitSuccessTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step :a
    fail :b, Output(:success) => Track(:success) #{}"End.success"
    fail :c, Output(:success) => Track(:success)

    Test.step(self, :a, :b, :c)
  end

  # a => true
  it { Create.( a_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a]] >} }
  # b => true
  it { Create.( a_return: false, b_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :b]] >} }
  # c => true
  it { Create.( a_return: false, b_return: false, c_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :b, :c]] >} }
  # a => b => c => false
  it { Create.( a_return: false, b_return: false, c_return: false, data: []).inspect(:data).must_equal %{<Result:false [[:a, :b, :c]] >} }

#   # require "trailblazer/developer"
#   # it { Trailblazer::Developer::Client.push( operation: Create, name: "ushi" ) }


#   #---
#   # with => Track(:success), steps can still be added before End.success and they will be executed.
  class Update < Create
    pass :d

    def d(options, data:, **)
      data << :d
    end
  end

  # a => true
  it { Update.( a_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :d]] >} }
  # b => true
  it { Update.( a_return: false, b_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :b, :d]] >} }
  # c => true
  it { Update.( a_return: false, b_return: false, c_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :b, :c, :d]] >} }
  # a => b => c => false
  it { Update.( a_return: false, b_return: false, c_return: false, data: []).inspect(:data).must_equal %{<Result:false [[:a, :b, :c]] >} }

  #---
  # failure steps reference End.success and not just the polarization. This won't call #d in failure=>success case.
  class Delete < Trailblazer::Operation
    step :a
    fail :b, Output(:success) => "End.success"
    fail :c, Output(:success) => "End.success"
    pass :d

    Test.step(self, :a, :b, :c)

    def d(options, data:, **)
      data << :d
    end
  end

  # a => true
  it { Delete.( a_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :d]] >} }
  # b => true
  it { Delete.( a_return: false, b_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :b]] >} }
  # c => true
  it { Delete.( a_return: false, b_return: false, c_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :b, :c]] >} }
  # a => b => c => false
  it { Delete.( a_return: false, b_return: false, c_return: false, data: []).inspect(:data).must_equal %{<Result:false [[:a, :b, :c]] >} }

  #---
  #       |----|
  # a --> b c--d --> E.s
  # |_____|_|_______ E.f
  class Connect < Trailblazer::Operation
    step :a
    step :b, Output(:success) => "d"
    step :c, magnetic_to: [] # otherwise :success will be an open input!
    pass :d, id: "d"

    Test.step(self, :a, :b, :c)

    def d(options, data:, **)
      data << :d
    end
  end

  # it { puts Trailblazer::Activity::Magnetic::Introspect.seq( Connect.decompose.first ) }

  # a => true
  it { Connect.( a_return: true, b_return: true,data: []).inspect(:data).must_equal %{<Result:true [[:a, :b, :d]] >} }
  # a => false
  it { Connect.( a_return: false, data: []).inspect(:data).must_equal %{<Result:false [[:a]] >} }
  # b => false
  it { Connect.( a_return: true, b_return: false, data: []).inspect(:data).must_equal %{<Result:false [[:a, :b]] >} }

  #---
  # |---------|
  # |         V
  # a    c----d --
  # |\   ^\    \
  # | \ /  V
  # |__f____g----E.f
  class Post < Trailblazer::Operation
    step :a, Output(:success) => "d", id: "a"
    fail :f, Output(:success) => "c"
    step :c, magnetic_to: [], id: "c" # otherwise :success will be an open input!
    fail :g
    step :d, id: "d"

    Test.step(self, :a, :f, :c, :g, :d)
  end

  pp Post["__sequence__"]

  # a => true
  it { Post.( a_return: true, d_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :d]] >} }
  # a => false
  it { Post.( a_return: false, f_return: false, g_return: nil, data: []).inspect(:data).must_equal %{<Result:false [[:a, :f, :g]] >} }
  # a => false, f => true
  it { Post.( a_return: false, f_return: true, c_return: true, d_return: true, data: []).inspect(:data).must_equal %{<Result:true [[:a, :f, :c, :d]] >} }
  # a => false, f => true, c => false
  it { Post.( a_return: false, f_return: true, c_return: false, g_return: true, data: []).inspect(:data).must_equal %{<Result:false [[:a, :f, :c, :g]] >} }
end
