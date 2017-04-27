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

    def decide!(options, decide:, **)
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
    pass ->(options, **)         { options["a"] = false }
    step ->(options, params, **) { options["b"] = params[:decide] }
    fail ->(options, **)         { options["c"] = true }
  end

  it { Update.({}, decide: true).inspect("a", "b", "c").must_equal %{<Result:true [false, true, nil] >} }
  it { Update.({}, decide: false).inspect("a", "b", "c").must_equal %{<Result:false [false, false, true] >} }
end


=begin
module MiniTest::Assertions
  def assert_inspect(text, subject)
    circuit, _ = subject.values
    map, _ = circuit.to_fields
    map.inspect.gsub(/0x.+?lambda\)/, "").gsub("Trailblazer::Circuit::", "").gsub("AlterTest::", "").must_equal(text)
  end
end
Trailblazer::Circuit::Activity.infect_an_assertion :assert_inspect, :must_inspect
=end
