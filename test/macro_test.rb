require "test_helper"
#- test
# macro [ task, {name} ]
# macro [ task, {name}, { alteration: } ] # see task_wrap_test.rb
# macro [ task, {name}, { alteration: }, {task_outputs} ] # for eg. nested

class MacroTest < Minitest::Spec
  MacroB = ->(( options, *args ), **) do
    options[:B] = true # we were here!

    [ options[:MacroB_return], [ options, *args ] ]
  end

  it "raises exception when macro doesn't provide :id" do
    assert_raises do

      Class.new(Trailblazer::Operation) do
        step( task: "<some macro>" )
      end

    end.message.must_equal %{No :id given for <some macro>}
  end


  class Create < Trailblazer::Operation
    step :a
    step task: MacroB, id: :MacroB, outputs: { :success => Activity::Output("Allgood", :success), :failure => Activity::Output("Fail!", :failure), :pass_fast => Activity::Output("Winning", :pass_fast) }
    step :c

    def a(options, **); options[:a] = true end
    def c(options, **); options[:c] = true end
  end

  # MacroB returns Allgood and is wired to the :success edge (right track).
  it { Create.( {}, MacroB_return: "Allgood" ).inspect(:a, :B, :c).must_equal %{<Result:true [true, true, true] >} }
  # MacroB returns Fail! and is wired to the :failure edge (left track).
  it { Create.( {}, MacroB_return: "Fail!" ).inspect(:a, :B, :c).must_equal %{<Result:false [true, true, nil] >} }
  # MacroB returns Winning and is wired to the :pass_fast edge.
  it { Create.( {}, MacroB_return: "Winning" ).inspect(:a, :B, :c).must_equal %{<Result:true [true, true, nil] >} }

  #- user overrides :plus_poles
  class Update < Trailblazer::Operation
    macro = { task: MacroB, id: :MacroB, outputs: { :success => Activity::Output("Allgood", :success), :failure => Activity::Output("Fail!", :failure), :pass_fast => Activity::Output("Winning", :pass_fast) } }

    step :a
    step macro, outputs: { :success => Activity::Output("Fail!", :success), :fail_fast => Activity::Output("Winning", :fail_fast), :failure => Activity::Output("Allgood", :failure) }
    # plus_poles: Test.plus_poles_for("Allgood" => :failure, "Fail!" => :success, "Winning" => :fail_fast)
    step :c

    def a(options, **); options[:a] = true end
    def c(options, **); options[:c] = true end
  end

  # MacroB returns Allgood and is wired to the :failure edge.
  it { Update.( {}, MacroB_return: "Allgood" ).inspect(:a, :B, :c).must_equal %{<Result:false [true, true, nil] >} }
  # MacroB returns Fail! and is wired to the :success edge.
  it { Update.( {}, MacroB_return: "Fail!" ).inspect(:a, :B, :c).must_equal %{<Result:true [true, true, true] >} }
  # MacroB returns Winning and is wired to the :fail_fast edge.
  it { Update.( {}, MacroB_return: "Winning" ).inspect(:a, :B, :c).must_equal %{<Result:false [true, true, nil] >} }
end
