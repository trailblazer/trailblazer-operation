require "test_helper"

class GraphTest < Minitest::Spec
  class A
    Right = Class.new
  end

  class B
  end

  Graph = Trailblazer::Operation::Graph
  Circuit = Trailblazer::Circuit

  let(:right_end_evt) { Trailblazer::Operation::Railway::End::Success.new(:right) }
  let(:left_end_evt)  { Trailblazer::Operation::Railway::End::Failure.new(:left) }

  it do
    start = Graph::Node( start_evt = Circuit::Start.new(:default), type: :start, id: [:Start, :default] )
    # start.inspect.must_equal %{data:{type::start,name:Start.default}}

    start[:id].must_equal [:Start, :default]
    start[:_wrapped].must_equal start_evt

    # right: End::Success.new(:right)
    # right_end  = start.connect!(Graph::Node( End::Success.new(:right), type: :end ), Graph::Edge(Circuit::Right, type: :right) )
    right_end  = start.connect!(node: start.Node( right_end_evt, type: :end, id: [:End, :right] ), edge: [ Circuit::Right, type: :right ] )
    left_end   = start.connect!(node: start.Node( left_end_evt,  type: :end, id: [:End, :left]  ), edge: [ Circuit::Left,  type: :left ] )

    a, edge = start.insert_before!(
      right_end,
      node:     [ A, id: [:A] ],
      outgoing: [ A::Right, type: :right ],
      incoming: ->(edge) { edge[:type] == :right }
    )

    a.must_be_instance_of Graph::Node
    edge.must_be_instance_of Graph::Edge

    start.to_h.must_equal({
      start_evt => { Circuit::Right => A, Circuit::Left => left_end_evt },
      A         => { A::Right => right_end_evt },
    })

    b, _ = start.insert_before!(
      a,
      node:     [ B, id: [:B] ],
      outgoing: [ Circuit::Right, type: :right ],
      incoming: ->(edge) { edge[:type] == :right }
    )

    b.connect!(node: left_end, edge: [ Circuit::Left, type: :left ])

    start.to_h.must_equal({
      start_evt => { Circuit::Right => B, Circuit::Left => left_end_evt },
      A         => { A::Right => right_end_evt },
      B         => { Circuit::Right => A, Circuit::Left => left_end_evt },
    })

    # start["some.id"]
  end
end
