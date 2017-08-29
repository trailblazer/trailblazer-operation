require "test_helper"
# require "trailblazer/developer"

class WireTest < Minitest::Spec
  Circuit = Trailblazer::Circuit
  DSL = Trailblazer::Operation::Railway::DSL
  Insert = Trailblazer::Operation::Railway::Insert

  MyEnd = Class.new(Circuit::End)
  ExceptionFromD = Class.new

  D = ->(signal, options, flow_options, *args) do
    options["D"] = [ options["a"], options["b"], options["c"] ]

    signal = options["D_return"]
    [ signal, options, flow_options, *args ]
  end

  #- manual via ::graph API
  class Create < Trailblazer::Operation
    step ->(options, **) { options["a"] = 1 }
    step ->(options, **) { options["b"] = 2 }, name: "b"

    # step provides insert_before, outputs, node_data

    add_element! [ [:attach!, target: [MyEnd.new(:myend), {id: _id="End.myend"}], edge: [Circuit::Left, {}], source: "Start.default"] ], id: _id

    add_element! Insert.insertion_wirings_for( task: D,
          insert_before: "End.success",
          outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }, ExceptionFromD => { role: :exception } }, # any outputs and their polarization, generic.
          connect_to:      { success: "End.success", failure: "End.failure", exception: "End.myend" }, # where do my task's outputs go?,
          node_data: { id: _id="d" }), id: _id #, before: :bla

    fail ->(options, **) { options["f"] = 4 }, id: "f"
    step ->(options, **) { options["c"] = 3 }, id: "c"

    # element MyMacro(), insert_before: "End.success", connect_to: { success: "End.success", failure: "End.myend" }
    # element MyMacro(), insert_before: "End.success", connect_to: { success: "End.success", failure: "End.myend" }, id: "MyMacro.2"
  end

  # myend ==> d
  it { Trailblazer::Operation::Inspect.(Create).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>#<Proc::21 (lambda)>,>b,End.myend,d,<<f,>c]} }

  # normal flow as D sits on the Right track.
  it { Create.({}, "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >} }
  # ends on MyEnd, without hitting fail.
  it { Create.({}, "D_return" => ExceptionFromD).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >} } # todo: HOW TO CHECK End instance?
  it { Create.({}, "D_return" => Circuit::Left).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >} } # todo: HOW TO CHECK End instance?

  class B < Trailblazer::Operation
    # here, D has a step interface!
    D = ->(options, a:raise, b:raise, **) {
      options["D"] = [ a, b, options["c"] ]

      options["D_return"]
    }

    ExceptionFromD = Class.new(Circuit::Signal) # for steps, return value has to be subclass of Signal to be passed through as a signal and not a boolean.

    step ->(options, **) { options["a"] = 1 }, id: "a"
    step ->(options, **) { options["b"] = 2 }, id: "b"

    attach  MyEnd.new(:myend), id: "End.myend"
    insert D,
      insert_before: "End.success",
      outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }, ExceptionFromD => { role: :exception } }, # any outputs and their polarization, generic.
      connect_to:    { success: "End.success", failure: "End.failure", exception: "End.myend" },
      id:            "d"

    fail ->(options, **) { options["f"] = 4 }, id: "f"
    step ->(options, **) { options["c"] = 3 }, id: "c"
  end

  it { Trailblazer::Operation::Inspect.(B).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>a,>b,End.myend,d,<<f,>c]} }

  # normal flow as D sits on the Right track.
  it { B.({}, "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >} }
  # ends on MyEnd, without hitting fail.
  it { B.({}, "D_return" => B::ExceptionFromD).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >} } # todo: HOW TO CHECK End instance?
  it { B.({}, "D_return" => Circuit::Left).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >} } # todo: HOW TO CHECK End instance?


  class C < Trailblazer::Operation
    # here, D has a step interface!
    D = ->(options, a:raise, b:raise, **) {
      options["D"] = [ a, b, options["c"] ]

      options["D_return"]
    }

    ExceptionFromD = Class.new(Circuit::Signal) # for steps, return value has to be subclass of Signal to be passed through as a signal and not a boolean.

    step ->(options, **) { options["a"] = 1 }, id: "a"
    step ->(options, **) { options["b"] = 2 }, id: "b"

    attach  MyEnd.new(:myend), id: "End.myend"
    step D,
      outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }, ExceptionFromD => { role: :exception } }, # any outputs and their polarization, generic.
      connect_to:    { success: "End.success", failure: "End.failure", exception: "End.myend" },
      id:            "d"

    fail ->(options, **) { options["f"] = 4 }, id: "f"
    step ->(options, **) { options["c"] = 3 }, id: "c"
  end

# require "trailblazer/developer"
# it { puts xml = Trailblazer::Diagram::BPMN.to_xml( C["__activity__"], C["__sequence__"] )

#     File.write("berry.bpmn", xml)
#   }


  it { Trailblazer::Operation::Inspect.(C).gsub(/0x.+?wire_test.rb/, "").must_equal %{[>a,>b,End.myend,>d,<<f,>c]} }

  # normal flow as D sits on the Right track.
  it { C.({}, "D_return" => Circuit::Right).inspect("a", "b", "c", "D", "f").must_equal %{<Result:true [1, 2, 3, [1, 2, nil], nil] >} }
  # ends on MyEnd, without hitting fail.
  it { C.({}, "D_return" => C::ExceptionFromD).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], nil] >} } # todo: HOW TO CHECK End instance?
  it { C.({}, "D_return" => Circuit::Left).inspect("a", "b", "c", "D", "f").must_equal %{<Result:false [1, 2, nil, [1, 2, nil], 4] >} } # todo: HOW TO CHECK End instance?


  #- connect
  class E < Trailblazer::Operation
    step ->(options, **) { options["a"] = 1 }, id: "a"
    step ->(options, b_return:, **) { options["b"] = 2; b_return }, id: "b"
    fail ->(options, f_return:, **) { options["f"] = 4; f_return }, id: "f"
    connect "f", edge: Circuit::Right, target: "End.success"

    step ->(options, **) { options["c"] = 3 }, id: "c"
  end

  it { E.({}, "b_return" => true).inspect("a", "b", "c", "f").must_equal %{<Result:true [1, 2, 3, nil] >} }
  # go to fail, but normal fail behavior.
  it { E.({}, "b_return" => false,
              "f_return" => false).inspect("a", "b", "c", "f").must_equal %{<Result:false [1, 2, nil, 4] >} }
  # go to fail and back to right track.
  it { E.({}, "b_return" => false,
              "f_return" => Circuit::Right).inspect("a", "b", "c", "f").must_equal %{<Result:true [1, 2, 3, 4] >} }

  # it { puts xml = Trailblazer::Diagram::BPMN.to_xml( E["__activity__"], E["__sequence__"] )
  #   File.write("berry2.bpmn", xml)
  # }


  #- add a node before End.failure and connect all other before that.
  class F < Trailblazer::Operation
    # 1
    step ->(options, **) { options["a"] = 1 }, id: "a"

    # 4
    # our success "end":
    step ->(options, **) { options["z"] = 2 }, id: "z"

    # 2
    pass ->(options, a:, **) { options["b"] = [a, options["c"], options["z"]].inspect },
      insert_before: "z", id: "b" #, connect_to: Right => Z #FIXME: we also need to change connect_to, e.g. connect_to: Merge( success: "z" )

    # 3
    pass ->(options, a:, b:, **) { options["c"] = [a,b, options["z"], 1] },
      insert_before: "z", id: "c"


    # fail ->(options, f_return:, **) { options["f"] = 4; f_return }, id: "f"
    # connect "f", edge: Circuit::Right, target: "End.success"

    # step ->(options, **) { options["c"] = 3 }, id: "c"
  end

  it { skip "implement" }
  # it { pp F['__sequence__'].to_a }
  # it { F.({}, "b_return" => false,
  #                                 ).inspect("a", "b", "c", "z").must_equal %{<Result:true [1, "[1, nil, nil]", [1, "[1, nil, nil]", nil], 2] >} }
  # it {
  #   puts xml = Trailblazer::Diagram::BPMN.to_xml( F["__activity__"], F["__sequence__"] )
  #   File.write("berry3.bpmn", xml)
  # }
end

class DoormatStepDocsTest < Minitest::Spec
  #:doormat-before
  class Create < Trailblazer::Operation
    step :first
    step :log_success!

    step :second, before: :log_success!
    step :third,  before: :log_success!

    fail :log_errors!, id: "log_errors"

    #~ignore
    def first(options, **)
      options["row"] = [:a]
    end

    # our success "end":
    def log_success!(options, **)
      options["row"] << :z
    end

    # 2
    def second(options, **)
      options["row"] << :b
    end

    # 3
    def third(options, **)
      options["row"] << :c
    end

    def log_errors!(options, **)
      options["row"] << :f
    end
    #~ignore end
  end
  #:doormat-before end

  # it { pp F['__sequence__'].to_a }
  it { Create.({}, "b_return" => false,
                                  ).inspect("row").must_equal %{<Result:true [[:a, :b, :c, :z]] >} }

    # require "trailblazer/developer"
    # xml = Trailblazer::Diagram::BPMN.to_xml( Create["__activity__"], Create["__sequence__"] )

    # token = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJpZCI6MywidXNlcm5hbWUiOiJhcG90b25pY2siLCJlbWFpbCI6Im5pY2tAdHJhaWxibGF6ZXIudG8ifQ."

    # require "faraday"
    # conn = Faraday.new(:url => 'https://api.trb.to')
    # response = conn.post do |req|
    #   req.url '/dev/v1/import'
    #   req.headers['Content-Type'] = 'application/json'
    #   req.headers["Authorization"] = token
    #   require "base64"

    #   req.body = %{{ "name": "Doormat/:before", "xml":"#{Base64.strict_encode64(xml)}" }}
    # end

    # puts response.status.inspect
end

class DoormatInheritanceTest < Minitest::Spec
  #:doormat-inheritance
  class Base < Trailblazer::Operation
    step :log_success!
    fail :log_errors!

    #~ignore
    # our success "end":
    def log_success!(options, **)
      options["row"] << :z
    end

    def log_errors!(options, **)
      options["row"] << :f
    end
    #~ignore end
  end
  #:doormat-inheritance end

  class Create < Base
    step :first, before: :log_success!
    step :second, before: :log_success!
    step :third,  before: :log_success!

    #~ignore
    def first(options, **)
      options["row"] = [:a]
    end

    # 2
    def second(options, **)
      options["row"] << :b
    end

    # 3
    def third(options, **)
      options["row"] << :c
    end
    #~ignore end
  end
  #:doormat-before end

  # it { pp F['__sequence__'].to_a }
  it { Create.({}, "b_return" => false,
                                  ).inspect("row").must_equal %{<Result:true [[:a, :b, :c, :z]] >} }
end

