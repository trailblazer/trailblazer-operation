require "test_helper"

class DeclarativeApiTest < Minitest::Spec
  #---
  #- step, pass, fail

  # Test: step/pass/fail
  # * do they deviate properly?
  class Create < Trailblazer::Operation
    step :decide!
    success :wasnt_ok!
    success :was_ok!
    failure :return_true!
    failure :return_false!

    def decide!(options, decide:raise, **o)
      options["a"] = true
      decide
    end

    def wasnt_ok!(options, **o)
      options["y"] = false
    end

    def was_ok!(options, **o)
      options["x"] = true
    end

    def return_true! (options, **o); options["b"] = true end
    def return_false!(options, **o); options["c"] = false end
  end

  it { Create.({}, decide: true).inspect("a", "x", "y", "b", "c").must_equal %{<Result:true [true, true, false, nil, nil] >} }
  it { Create.({}, decide: false).inspect("a", "x", "y", "b", "c").must_equal %{<Result:false [true, nil, nil, true, false] >} }

  #---
  #- trace

  it do

  end

  #---
  #- empty class
  class Noop < Trailblazer::Operation
  end

  it { Noop.().inspect("params").must_equal %{<Result:true [{}] >} }

  #---
  #- pass
  #- fail
  class Update < Trailblazer::Operation
    pass ->(options, **o)         { options["a"] = false }
    step ->(options, params:raise, **o) { options["b"] = params[:decide] }
    fail ->(options, **o)         { options["c"] = true }
  end

  it { Update.(decide: true).inspect("a", "b", "c").must_equal %{<Result:true [false, true, nil] >} }
  it { Update.(decide: false).inspect("a", "b", "c").must_equal %{<Result:false [false, false, true] >} }
end
