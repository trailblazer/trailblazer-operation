require "test_helper"

class GraphTest < Minitest::Spec
  class A
    Right = Class.new
  end

  class B
  end

  class C
    Left = Class.new
  end

  class D
  end

  Graph = Trailblazer::Operation::Graph
  Circuit = Trailblazer::Circuit

  let(:right_end_evt) { Trailblazer::Operation::Railway::End::Success.new(:right) }
  let(:left_end_evt)  { Trailblazer::Operation::Railway::End::Failure.new(:left) }

  it do
    start = Graph::Node( start_evt = Circuit::Start.new(:default), type: :event, id: [:Start, :default] )
    # start.inspect.must_equal %{data:{type::start,name:Start.default}}

    start[:id].must_equal [:Start, :default]
    start[:_wrapped].must_equal start_evt

    # right: End::Success.new(:right)
    # right_end  = start.connect!(Graph::Node( End::Success.new(:right), type: :end ), Graph::Edge(Circuit::Right, type: :right) )
    right_end  = start.connect!(node: start.Node( right_end_evt, type: :end, id: [:End, :right] ), edge: [ Circuit::Right, type: :right ] )
    left_end   = start.attach!(node: [ left_end_evt, type: :event, id: [:End, :left] ], edge: [ Circuit::Left,  type: :left ] )

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


    #- no outgoing (e.g. when connecting manually)
    c, edge = start.insert_before!(
      left_end,
      node:     [ C, id: [:C] ],
      incoming: ->(edge) { edge[:type] == :left }
    )

    start.to_h.must_equal({
      start_evt => { Circuit::Right => B, Circuit::Left => C },
      A         => { A::Right => right_end_evt },
      B         => { Circuit::Right => A, Circuit::Left => C },
      C         => {},
    })
    # DISCUSS: now left_end is unconnected and invisible.

    # start["some.id"]
  end

  #- insert with id
  it do
    start      = Graph::Node( start_evt = Circuit::Start.new(:default), type: :event, id: [:Start, :default] )
    right_end  = start.attach!(node: [ right_end_evt, type: :event, id: [:End, :right] ], edge: [ Circuit::Right, type: :right ] )
    left_end   = start.attach!(node: [ left_end_evt, type: :event, id: [:End, :left] ], edge: [ Circuit::Left,  type: :left ] )

    d, edge = start.insert_before!(
      [:End, :right],
      node:     [ D, id: [:D] ],
      incoming: ->(edge) { edge[:type] == :right },
      outgoing: [ Circuit::Right, type: :right ]
    )

    start.to_h.must_equal({
      start_evt => { Circuit::Right => D, Circuit::Left => left_end_evt },
      D         => { Circuit::Right => right_end_evt }
    })

    #- #find with block TODO: test explicitly.
    events = start.find_all { |node| node[:type] == :event }
    events.must_equal [start, left_end, right_end]

    # TODO: test find_all/successors leafs explicitly.
    leafs = start.find_all { |node| node.successors.size == 0 }
    leafs.must_equal [ left_end, right_end ]


    start.connect!( node: [:End, :right], edge: [ Circuit, {} ] )

    start.to_h.must_equal({
      start_evt => { Circuit::Right => D, Circuit::Left => left_end_evt, Circuit => right_end_evt },
      D         => { Circuit::Right => right_end_evt }
    })
  end
end
# TODO: test attach! properly.
# TODO: test/fix double entries in find_all
