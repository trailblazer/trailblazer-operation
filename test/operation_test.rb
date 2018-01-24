require "test_helper"

class DeclarativeApiTest < Minitest::Spec
  #---
  #- step, pass, fail

  # Test: step/pass/fail
  # * do they deviate properly?
  class Create < Trailblazer::Operation
    step :decide!
    pass :wasnt_ok!
    pass :was_ok!
    fail :return_true!
    fail :return_false!

    def decide!(options, decide:raise, **)
      options["a"] = true
      decide
    end

    def wasnt_ok!(options, **)
      options["y"] = false
    end

    def was_ok!(options, **)
      options["x"] = true
    end

    def return_true! (options, **); options["b"] = true end
    def return_false!(options, **); options["c"] = false end
  end

  it { Create.(decide: true).inspect("a", "x", "y", "b", "c").must_equal %{<Result:true [true, true, false, nil, nil] >} }
  it { Create.(decide: false).inspect("a", "x", "y", "b", "c").must_equal %{<Result:false [true, nil, nil, true, false] >} }

  #---
  #- trace

  it do

  end

  #---
  #- empty class
  class Noop < Trailblazer::Operation
  end

  it { Noop.().inspect("params").must_equal %{<Result:true [nil] >} }

  #---
  #- pass
  #- fail
  class Update < Trailblazer::Operation
    pass ->(options, **)         { options["a"] = false }
    step ->(options, params:raise, **) { options["b"] = params[:decide] }
    fail ->(options, **)         { options["c"] = true }
  end

  it { Update.("params" => {decide: true}).inspect("a", "b", "c").must_equal %{<Result:true [false, true, nil] >} }
  it { Update.("params" => {decide: false}).inspect("a", "b", "c").must_equal %{<Result:false [false, false, true] >} }

  #---
  #- inheritance
  class Upsert < Update
    step ->(options, **) { options["d"] = 1 }
  end

  class Unset < Upsert
    step ->(options, **) { options["e"] = 2 }
  end

  it "allows to inherit" do
    Upsert.("params" => {decide: true}).inspect("a", "b", "c", "d", "e").must_equal %{<Result:true [false, true, nil, 1, nil] >}
    Unset. ("params" => {decide: true}).inspect("a", "b", "c", "d", "e").must_equal %{<Result:true [false, true, nil, 1, 2] >}
  end

  describe "Activity::Interface" do
    class Edit < Trailblazer::Operation
      step :a
      step :b, fast_track: true
    end

    it "provides #outputs" do
      Activity::Introspect.Outputs(Edit.outputs).must_equal %{success=> (#<Trailblazer::Operation::Railway::End::Success semantic=:success>, success)
failure=> (#<Trailblazer::Operation::Railway::End::Failure semantic=:failure>, failure)
pass_fast=> (#<Trailblazer::Operation::Railway::End::PassFast semantic=:pass_fast>, pass_fast)
fail_fast=> (#<Trailblazer::Operation::Railway::End::FailFast semantic=:fail_fast>, fail_fast)}
    end

    it "is an Interface" do
      Edit.is_a?( Activity::Interface ).must_equal true
    end
  end
end
