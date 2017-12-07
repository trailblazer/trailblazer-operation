# require "test_helper"

# class WiringWithNestedTest < Minitest::Spec
#   MyEnd = Class.new(Trailblazer::Circuit::End)

#   class Create < Trailblazer::Operation
#     class Edit < Trailblazer::Operation
#       step :a

#       def a(options, a_return:, **)
#         options["a"] = 1
#         a_return
#       end

#       # operations should expose their outputs with proper naming.
#       #
#       # {#<Trailblazer::Operation::Railway::End::Success:0x00000001b22310
#       #   @name=:success,
#       #   @options={}>=>{:role=>:success},
#       #  #<Trailblazer::Operation::Railway::End::Failure:0x00000001b222c0
#       #   @name=:failure,
#       #   @options={}>=>{:role=>:unauthorized}}
#       def self.outputs
#         # Outputs::Only(super, :success, :failure)
#         # Outputs::Update( outputs, failure: { role: :unauthorized}  )

#         outs = super.to_a

#         outs = Hash[*(outs[0]+outs[1])]

#         outs.merge( outs.keys[1] => { role: :unauthorized } )
#       end
#     end

#     attach MyEnd.new(:myend), id: "End.unauthorized"

#     step ( { task: Trailblazer::Activity::Subprocess( Edit, call: :__call__ ),
#       node_data:  { id: "Nested/" },
#       outputs:    Edit.outputs, # THIS SHOULD OVERRIDE.
#       connect_to: Merge({ unauthorized: "End.unauthorized" }) # connects :success automatically.
#       }), fast_track: true

#     step :b
#     fail :f

#     def b(options, a:, **)
#       options["b"] = a+1
#     end

#     def f(options, a:, **)
#       options["f"] = a+2
#     end
#   end

#   # Edit ==> true, will run :b
#   it do
#     result = Create.({}, a_return: true )
#     result.inspect("a", "b", "f").must_equal %{<Result:true [1, 2, nil] >}
#     result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Success
#   end

#   # Edit ==> false, will end on End.unauthorized.
#   it do
#     result = Create.({}, a_return: false )
#     result.inspect("a", "b", "f").must_equal %{<Result:false [1, nil, nil] >}
#     result.event.must_be_instance_of MyEnd

#     # Create.trace({}, a_return: false ).wtf
#   end
# end
