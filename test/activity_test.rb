require "test_helper"

class ActivityTest < Minitest::Spec
  Circuit = Trailblazer::Circuit

  A = ->(*) { snippet }
  B = ->(*) { snippet }

  let(:end_for_success) { Circuit::End.new(:success) }

  it do
    # Start   = Circuit::Start.new(:default)

    activity = Trailblazer::Activity.from_wirings(
      [
        [ :attach!, target: [ A, id: "A", type: :task ], edge: [ Circuit::Right, type: :railway ] ],
        [ :attach!, source: "A", target: [ end_for_success, type: :event, id: [:End, :success] ], edge: [ Circuit::Right, type: :railway ] ],
      ]
    )

    activity.circuit.to_fields.must_equal(
      [
        {
          activity.instance_variable_get(:@start_event) => { Circuit::Right => A },
          A => { Circuit::Right => end_for_success }
        },
        [end_for_success],
        {}
      ]
    )
  end
end

