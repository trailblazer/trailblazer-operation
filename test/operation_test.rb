require "test_helper"

class DeclarativeApiTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step :decide!
    success :wasnt_ok!
    success :was_ok!
  #   failure :wasnt_ok!

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
  end

  it "what" do
    puts Create["pipetree"].inspect
  end

  it { Create.({}, decide: true).inspect("a", "x", "y").must_equal %{<Result:true [true, true, false] >} }
  it { Create.({}, decide: false).inspect("a", "x", "y").must_equal %{<Result:true [true] >} }
end

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
