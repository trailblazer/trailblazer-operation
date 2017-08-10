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
  let(:start_evt)     { Circuit::Start.new(:default) }
  let(:start)         { Graph::Node( start_evt, type: :event, id: [:Start, :default] ) }

  it do
    start[:id].must_equal [:Start, :default]
    start[:_wrapped].must_equal start_evt

    # right: End::Success.new(:right)
    # right_end  = start.connect!(Graph::Node( End::Success.new(:right), type: :end ), Graph::Edge(Circuit::Right, type: :right) )
    right_end  = start.connect!(target: start.Node( right_end_evt, type: :end, id: [:End, :right] ), edge: [ Circuit::Right, type: :right ] )
    left_end   = start.attach!(target: [ left_end_evt, type: :event, id: [:End, :left] ], edge: [ Circuit::Left,  type: :left ] )

    a, edge = start.insert_before!(
      right_end,
      node:     [ A, id: [:A] ],
      outgoing: [ A::Right, type: :right ],
      incoming: ->(edge) { edge[:type] == :right }
    )

    a.must_be_instance_of Graph::Node
    edge.must_be_nil

    start.to_h( include_leafs: false).must_equal({
      start_evt => { Circuit::Right => A, Circuit::Left => left_end_evt },
      A         => { A::Right => right_end_evt },
    })

    b, _ = start.insert_before!(
      a,
      node:     [ B, id: [:B] ],
      outgoing: [ Circuit::Right, type: :right ],
      incoming: ->(edge) { edge[:type] == :right }
    )

    b.connect!(target: left_end, edge: [ Circuit::Left, type: :left ])

    start.to_h( include_leafs: false).must_equal({
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

    start.to_h( include_leafs: false ).must_equal({
      start_evt => { Circuit::Right => B, Circuit::Left => C },
      A         => { A::Right => right_end_evt },
      B         => { Circuit::Right => A, Circuit::Left => C },
      # C         => {},
    })
    # DISCUSS: now left_end is unconnected and invisible.

    # start["some.id"]

    #- attach! with :source
    start.attach!(source: [:C], target: [ D, id: "D" ], edge: [ Circuit::Right,  type: :middle ] )

    start.to_h( include_leafs: false ).must_equal({
      start_evt => { Circuit::Right => B, Circuit::Left => C },
      A         => { A::Right => right_end_evt },
      B         => { Circuit::Right => A, Circuit::Left => C },
      C         => { Circuit::Right => D },
    })
  end

  #- insert with id
  it do
    right_end  = start.attach!(target: [ right_end_evt, type: :event, id: [:End, :right] ], edge: [ Circuit::Right, type: :right ] )
    left_end   = start.attach!(target: [ left_end_evt, type: :event, id: [:End, :left] ], edge: [ Circuit::Left,  type: :left ] )

    d, edge = start.insert_before!(
      [:End, :right],
      node:     [ D, id: [:D] ],
      incoming: ->(edge) { edge[:type] == :right },
      outgoing: [ Circuit::Right, type: :right ]
    )

    start.to_h( include_leafs: false).must_equal({
      start_evt => { Circuit::Right => D, Circuit::Left => left_end_evt },
      D         => { Circuit::Right => right_end_evt }
    })

    #- #find with block TODO: test explicitly.
    events = start.find_all { |node| node[:type] == :event }
    events.must_equal [start, right_end, left_end]

    # TODO: test find_all/successors leafs explicitly.
    leafs = start.find_all { |node| node.successors.size == 0 }
    leafs.must_equal [ right_end, left_end ]


    start.connect!( target: [:End, :right], edge: [ Circuit, {} ] )

    start.to_h( include_leafs: false).must_equal({
      start_evt => { Circuit::Right => D, Circuit::Left => left_end_evt, Circuit => right_end_evt },
      D         => { Circuit::Right => right_end_evt }
    })
  end




  it do
    right_end  = start.connect!(target: start.Node( right_end_evt, type: :end, id: [:End, :right] ), edge: [ Circuit::Right, type: :railway ] )
    left_end   = start.attach!(target: [ left_end_evt, type: :event, id: [:End, :left] ], edge: [ Circuit::Left,  type: :left ] )

    a, edge = start.insert_before!(
      [:End, :right],
      node:     [ A, id: :A ],
      outgoing: [ Circuit::Right, type: :railway ],
      incoming: ->(edge) { edge[:type] == :railway }
    )
    target = start.connect!( source: :A, edge: [ Circuit::Left, type: :railway ], target: [:End, :left] )

    start.to_h( include_leafs: false).must_equal({
      start_evt => { Circuit::Right => A, Circuit::Left => left_end_evt },
      A         => { Circuit::Right => right_end_evt, Circuit::Left => left_end_evt }
    })
  end

  #- detach a node via #insert_before! without :outgoing
  #- then, connect! that "leaf" node.
  it do
    right_end = start.attach!(target: [ right_end_evt, type: :event, id: [:End, :right] ], edge: [ Circuit::Right, type: :railway ] )
    right_end_evt = right_end[:_wrapped]

    a, edge = start.insert_before!(
      [:End, :right],
      node:     [ A, id: :A ],
      # outgoing: [ Circuit::Right, type: :railway ],
      incoming: ->(edge) { edge[:type] == :railway }
    )

    start.to_h.must_equal(
      {
        start_evt     => { Circuit::Right => A },
        A             => {}, # A not connected, it's a leaf.
        right_end_evt => {}, # End.right is orphaned.
      }
    )

    start.connect!( source: :A, edge: [ Circuit::Left, {} ], target: [:End, :right] )

    start.to_h(include_leafs: false).must_equal(
      {
        start_evt     => { Circuit::Right => A },
        A             => { Circuit::Left => right_end_evt }, # A is now connected!
      }
    )
  end

  #- detach a node via #insert_before! without :outgoing
  #- then, insert_before! another node "before" the orphaned, and omit :outgoing.
  it do
    right_end = start.attach!(target: [ right_end_evt, type: :event, id: [:End, :right] ], edge: [ Circuit::Right, type: :railway ] )
    right_end_evt = right_end[:_wrapped]

    a, edge = start.insert_before!(
      [:End, :right],
      node:     [ A, id: :A ],
      # outgoing: [ Circuit::Right, type: :railway ],
      incoming: ->(edge) { edge[:type] == :railway }
    )

    start.to_h.must_equal(
      {
        start_evt     => { Circuit::Right => A },
        A             => {}, # A not connected, it's a leaf.
        right_end_evt => {}, # End.right is orphaned, and doesn't have incoming edges.
      }
    )

    start.insert_before!( [:End, :right], node: [ B, {id: :B} ], incoming: ->(edge) { edge[:type] == :railway } )

    start.to_h.must_equal(
      {
        start_evt     => { Circuit::Right => A },
        A             => {}, # A is not connected!
        B =>{},
        right_end_evt => {},
      }
    )
  end

  #- raises exception when same ID is inserted multiple times
  it do
    right_end = start.attach!(target: [ right_end_evt, type: :event, id: [:End, :right] ], edge: [ Circuit::Right, type: :railway ] )
    # right_end = start.attach!(target: [ right_end_evt, type: :event, id: [:End, :right] ], edge: [ Circuit::Right, type: :railway ] )

    a, edge = start.insert_before!(
      [:End, :right],
      node:     [ A, id: :A ],
      outgoing: [ Circuit::Right, type: :railway ],
      incoming: ->(edge) { edge[:type] == :railway }
    )

    exception = assert_raises Trailblazer::Operation::Graph::IllegalNodeError do
      a, edge = start.insert_before!(
        [:End, :right],
        node:     [ A, id: :A ],
        outgoing: [ Circuit::Right, type: :railway ],
        incoming: ->(edge) { edge[:type] == :railway }
      )
    end

    exception.message.must_equal "The ID `A` has been added before."
  end
end
# TODO: test attach! properly.
# TODO: test double entries in find_all
