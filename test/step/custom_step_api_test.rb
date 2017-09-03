# require "test_helper"

# #---
# #- Using your own step builder

# class StepWithMyOwnDSLTest < Minitest::Spec
#   Signal = Class.new(Trailblazer::Circuit::Direction)

#   MyTaskBuilder = ->(step, ontruefalse) do
#     ->(direction, *args) { step.(direction, *args); [ Signal, *args ] }
#   end

#   class Create < Trailblazer::Operation
#     def self.task(proc, options)
#       activity = self["__activity__"]

#       step_args = Railway::DSL::StepArgs.new( [proc, options], Trailblazer::Circuit::Right, [[Signal, activity[:End, :right]]], ["asdfasfds Circuit::Left, Circuit::Left"], activity[:End, :right] )

#       # FIXME: no inheritance, yet.
#       self["__activity__"] = add(activity, self["__sequence__"], step_args, MyTaskBuilder)
#     end

#     task ->(direction, options, flow_options) { options["x"] = direction }, name: :a
#     task ->(direction, options, flow_options) { options["y"] = direction }, name: :b
#   end

#   it { Trailblazer::Operation::Inspect.(Create).gsub(/0x.+?step_test.rb/, "").must_equal %{[>a,>b]} }
#   it {
#     skip "TODO: work on better DSL API."
#     Create.().inspect("x", "y").must_equal %{<Result:true [StepWithDeprecatedMacroTest::Create, StepWithDeprecatedMacroTest::Create] >} }
# end
