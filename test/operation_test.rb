require "test_helper"

class DeclarativeApiTest < Minitest::Spec
  # class Create < Trailblazer::Operation
  #   step :decide!
  #   success :was_ok!
  #   failure :wasnt_ok!

  #   def decide!(options, ok:, **)
  #     options["a"] = true
  #     ok
  #   end

  #   def was_ok!(options, **)
  #     options["x"] = true
  #   end
  # end

  it { Create.({}, ok: true).inspect("a", "x", "y").must_equal %{<Result:true [true, true, nil] >} }
  it { Create.({}, ok: false).inspect("a", "x", "y").must_equal %{<Result:true [true] >} }
end

class BlaTest < Minitest::Spec
  Circuit = Trailblazer::Circuit

  it do

    railway = [
      [ :decide!, :right, Circuit::Right, :step ],
      [ :was_ok!, :right, Circuit::Right, :pass ],
      [ :wasnt_ok!, :left, Circuit::Left, :fail ],
    ]

    activity = Circuit::Activity({id: "A/"}, end: { right: Circuit::End.new(:right), left: Circuit::End.new(:left) }) { |evt|
      {
        evt[:Start] => { Circuit::Right => evt[:End, :right], Circuit::Left => evt[:End, :left] },
      }
    }

    railway.each do |(step, track, direction, type)|

      activity = Circuit::Activity::Alter(activity, :before, activity[:End, track], step, direction: direction) # TODO: direction => outgoing
      activity = Circuit::Activity::Connect(activity, step, Circuit::Left, activity[:End, :left]) if type == :step
    end

    activity.must_inspect "{#<Start: default {}>=>{Right=>:decide!, Left=>:wasnt_ok!}, :decide!=>{Right=>:was_ok!, Left=>:wasnt_ok!}, :was_ok!=>{Right=>#<End: right {}>}, :wasnt_ok!=>{Left=>#<End: left {}>}}"
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
