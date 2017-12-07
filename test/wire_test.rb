# require "test_helper"
# # require "trailblazer/developer"

# class WireTest < Minitest::Spec
#   Circuit = Trailblazer::Circuit
#   ExceptionFromD = Class.new               # custom signal

#   D = ->((options, *args), *) do
#     options["D"] = [ options["a"], options["b"], options["c"] ]

#     signal = options["D_return"]
#     [ signal, [ options, *args ] ]
#   end

#   #---
#   #- step providing all :outputs manually.
#   class Create < Trailblazer::Operation
#     step ->(options, **) { options["a"] = 1 }
#     step ->(options, **) { options["b"] = 2 }, name: "b"

#     step( { task: D,
#       outputs: { Circuit::Right => :success, Circuit::Left => :failure, ExceptionFromD => :exception }, # any outputs and their polarization, generic.
#       id: :d,
#       },
#       :exception => MyEnd = End("End.ExceptionFromD_happened")
#     )

#     fail ->(options, **) { options["f"] = 4 }, id: "f"
#     step ->(options, **) { options["c"] = 3 }, id: "c"
#   end

#   # myend ==> d
#   it { Trailblazer::Operation::Inspect.(Create).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>#<Proc::18 (lambda)>,>b,>d,<<f,>c]} }

#   # normal flow as D sits on the Right track.
#   it do
#     result = Create.({}, "D_return" => Circuit::Right)

#     result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >}
#     result.event.must_equal Create.outputs.keys[1]
#   end

#   # ends on MyEnd, without hitting fail.
#   it do
#     result = Create.({}, "D_return" => ExceptionFromD)

#     result.event.must_equal Create::MyEnd
#     result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >}
#   end

#   # normal flow to left track.
#   it do
#     result = Create.({}, "D_return" => Circuit::Left)

#     result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >}
#     result.event.must_equal Create.outputs.keys[0]
#   end

#   #---
#   #- step with Merge
#   class CreateWithDefaults < Trailblazer::Operation
#     step ->(options, **) { options["a"] = 1 }
#     step ->(options, **) { options["b"] = 2 }, name: "b"

#     step( { task: D,
#       outputs: Merge( ExceptionFromD => { role: :exception } ), # any outputs and their polarization, generic.
#       id: :d,
#       },
#       :exception => MyEnd = End("End.ExceptionFromD_happened")
#     )

#     fail ->(options, **) { options["f"] = 4 }, id: "f"
#     step ->(options, **) { options["c"] = 3 }, id: "c"
#   end

#   # normal flow as D sits on the Right track.
#   it do
#     result = CreateWithDefaults.({}, "D_return" => Circuit::Right)

#     result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >}
#     result.event.must_equal CreateWithDefaults.outputs.keys[1]
#   end

#   # ends on MyEnd, without hitting fail.
#   it do
#     result = CreateWithDefaults.({}, "D_return" => ExceptionFromD)

#     result.event.must_equal CreateWithDefaults::MyEnd
#     result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >}
#   end

#   # normal flow to left track.
#   it do
#     result = CreateWithDefaults.({}, "D_return" => Circuit::Left)

#     result.inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >}
#     result.event.must_equal CreateWithDefaults.outputs.keys[0]
#   end

# end

# class WireExceptionTest < Minitest::Spec
#   # role in :outputs can't be connected because not in :connect_to.
#   it do
#     exception = assert_raises do
#       class Create < Trailblazer::Operation
#         step :a, outputs: { "some" => { role: :success } }, connect_to: { :not_existent => "End.success" }
#       end
#     end

#     exception.message.must_equal %{Couldn't map output role :success for {:not_existent=>"End.success"}}
#   end
# end
