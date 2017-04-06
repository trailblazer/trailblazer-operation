require "test_helper"

class DeclarativeApiTest < Minitest::Spec
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
end

=begin
class BlaTest < Minitest::Spec
  Circuit = Trailblazer::Circuit

  it do

    # pass pass_fast: true => wires directly to End.pass_fast
    # fail fail_fast: true => wires directly to End.fail_fast
    # step fail_fast: true => wires directly to End.fail_fast
    # step pass_fast: true => wires directly to End.pass_fast


    activity = Circuit::Activity({id: "A/"}, end: {
      right: Circuit::End.new(:right), left: Circuit::End.new(:left),
      pass_fast: Circuit::End.new(:pass_fast), fail_fast: Circuit::End.new(:fail_fast) }
    ) { |evt|

      {
        evt[:Start] => { Circuit::Right => evt[:End, :right], Circuit::Left => evt[:End, :left] },
      }
    }

    railway = [
      [ :decide!, :right, Circuit::Right, [[Circuit::Left, :left]] ], # step
      [ :was_ok!, :right, Circuit::Right, [] ], # pass
      [ :wasnt_ok!, :left, Circuit::Left, [] ], # fail
      [ :handle!, :left, Circuit::Left, [] ],   # fail
    ]



    activity.must_inspect "{#<Start: default {}>=>{Right=>:decide!, Left=>:wasnt_ok!}, :decide!=>{Right=>:was_ok!, Left=>:wasnt_ok!}, :was_ok!=>{Right=>#<End: right {}>}, :wasnt_ok!=>{Left=>:handle!}, :handle!=>{Left=>#<End: left {}>}}"
  end
end


module MiniTest::Assertions
  def assert_inspect(text, subject)
    circuit, _ = subject.values
    map, _ = circuit.to_fields
    map.inspect.gsub(/0x.+?lambda\)/, "").gsub("Trailblazer::Circuit::", "").gsub("AlterTest::", "").must_equal(text)
  end
end
Trailblazer::Circuit::Activity.infect_an_assertion :assert_inspect, :must_inspect
=end
