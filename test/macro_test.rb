require "test_helper"
#- test
# macro [ task, {name} ]
# macro [ task, {name}, { alteration: } ] # see task_wrap_test.rb
# macro [ task, {name}, { alteration: }, {task_outputs} ] # for eg. nested

class MacroTest < Minitest::Spec
  MacroB = ->(direction, options, flow_options) do
    options[:B] = true # we were here!

    [ options[:MacroB_return], options, flow_options ]
  end

  class Create < Trailblazer::Operation
    step :a
    step [ MacroB, { name: :MacroB }, {}, { "Allgood" => { role: :success }, "Fail!" => { role: :failure } } ]
    step :c

    def a(options, **); options[:a] = true end
    def c(options, **); options[:c] = true end
  end

  # MacroB returns Allgood and is wired to the :success edge (right track).
  it { Create.( {}, MacroB_return: "Allgood" ).inspect(:a, :B, :c).must_equal %{<Result:true [true, true, true] >} }
  # MacroB returns Fail! and is wired to the :failure edge (left track).
  it { Create.( {}, MacroB_return: "Fail!" ).inspect(:a, :B, :c).must_equal %{<Result:false [true, true, nil] >} }
end
