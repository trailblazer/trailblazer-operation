require "test_helper"

# Tests around {Operation.call}.
class OperationTest < Minitest::Spec
  def assert_aliasing(result)
    assert_equal result.success?, true
    assert_equal result[:params], {id: 1}
    assert_equal result[:parameters], {id: 1}
  end

  it "canonical invoke using {Operation.__}" do
    # Trailblazer::Operation.()# calls {  }.
    operation_class = Trailblazer::Operation

    result = operation_class.(params: {id: 1})

    # {Operation.__} returns circuit-interface return set.
    signal, (result, _) = operation_class.__(operation_class, {params: {id: 1}})

    assert_equal signal.to_h[:semantic], :success

    stdout, _ = capture_io do
      signal, (result, _) = operation_class.__?(operation_class, {params: {id: 1}})
    end

    assert_equal CU.strip(stdout), %(Trailblazer::Operation
|-- \e[32mStart.default\e[0m
`-- End.success\n)
  end

  it "canonical invoke #__ allows a second argument and accepts the {:invoke_method} option" do
    operation_class = Trailblazer::Operation
    signal, result = nil

    stdout, _ = capture_io do
      signal, (result, _) = operation_class.__(operation_class, {params: {id: 1}}, invoke_method: Trailblazer::Developer::Wtf.method(:invoke))
    end

    assert_equal signal.to_h[:semantic], :success
    assert_equal CU.strip(stdout), %(Trailblazer::Operation
|-- \e[32mStart.default\e[0m
`-- End.success\n)
  end

  it "we can use the circuit-interface and inject options like {:runner}" do
    # Internally, TaskWrap::Runner.call_task invokes the circuit-interface.
    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(Trailblazer::Operation, [{id: 1}, {}])

    assert_equal signal.to_h[:semantic], :success
    assert_equal ctx.class, Hash # because canonical invoke is not called.
  end

  # test that circuit-interface doesn't use dynamic args / (e.g. aliasing)
  it "circuit-interface doesn't use dynamic args from {configure!}" do
    operation_class = Class.new(Trailblazer::Operation)
    operation_class.configure! do
      {
        flow_options: {
          context_options: {
            aliases: { "seq" => :sequence },
            container_class: Trailblazer::Context::Container::WithAliases,
          }
        }
      }
    end

    result = operation_class.({seq: []})
    assert_equal result[:sequence], [] # with public_call, we use {configure!} and can see the alias.

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(Trailblazer::Operation, [{seq: []}, {}])

    assert_equal ctx.class, Hash
    assert_equal ctx[:seq], []
    assert_nil ctx[:sequence]
  end

  it "{Operation.wtf?}" do
    operation_class = Class.new(Trailblazer::Operation)
    operation_class.configure! do
      {
        flow_options: {
          context_options: {
            aliases: { "seq" => :sequence },
            container_class: Trailblazer::Context::Container::WithAliases,
          }
        }
      }
    end
    signal, result = nil

    stdout, _ = capture_io do
      result = operation_class.wtf?({seq: []})
    end

    assert_equal CU.strip(stdout), %(#<Class:0x>
|-- \e[32mStart.default\e[0m
`-- End.success\n)
    assert_equal result[:sequence], [] # aliasing  works.
  end
  # test Op.wtf?
  # test matcher block interface

  # TODO: test overriding configure! options etc in subclasses


  class Noop < Trailblazer::Operation
    def self.capture_circuit_options((ctx, flow_options), **circuit_options)
      ctx[:capture_circuit_options] = circuit_options.keys.inspect

      return Trailblazer::Activity::Right, [ctx, flow_options]
    end

    step task: method(:capture_circuit_options)
  end

  # Mixing keywords and string keys in {Operation.call}.
  # Test that {.(params: {}, "current_user" => user)} is processed properly

  it "doesn't mistake circuit options as ctx variables when using circuit-interface" do
    signal, (ctx, _) = Noop.call(
      [{params: {}}, {}],
      # real circuit_options
      variable_for_circuit_options: true
    ) # call_with_public_interface
    #@ {:variable_for_circuit_options} is not supposed to be in {ctx}.
    assert_equal CU.inspect(ctx), %({:params=>{}, :capture_circuit_options=>"[:variable_for_circuit_options, :exec_context, :activity, :runner]"})
  end

  it "doesn't mistake circuit options as ctx variables when using the call interface" do
    result = Noop.call(
      params:           {},
      model:            true,
      "current_user" => Object
    ) # call with public interface.
    #@ {:variable_for_circuit_options} is not supposed to be in {ctx}.
    assert_result result, {params: {}, model: true, current_user: Object, capture_circuit_options: "[:wrap_runtime, :activity, :exec_context, :runner]"}
  end

#@ {#call_with_public_interface}
  it "doesn't mistake circuit options as ctx variables when using circuit-interface" do
    result = Noop.call_with_public_interface(
      {params: {}},
      {},
      variable_for_circuit_options: true
    ) # call_with_public_interface has two positional args, and kwargs for {circuit_options}.

    assert_result result, {params: {}, capture_circuit_options: "[:variable_for_circuit_options, :wrap_runtime, :activity, :exec_context, :runner]"}
    # assert_equal result.inspect, %(<Result:true #<Trailblazer::Context::Container wrapped_options={:params=>{}} mutable_options={:capture_circuit_options=>\"[:variable_for_circuit_options, :wrap_runtime, :activity, :exec_context, :runner]\"}> >)
  end
end

# TODO: remove this test as many cases are covered via autogenerated activity tests.

class DeclarativeApiTest < Minitest::Spec
  it "doesn't invoke {call} twice when using public interface" do
    class MyOp < Trailblazer::Operation
      @@GLOBAL = []
      def self.global; @@GLOBAL; end


      def self.call(*args)
        @@GLOBAL << :call
        super
      end

      pass :model

      def model(ctx, **)
        @@GLOBAL << :model
      end
    end

    MyOp.({})
    assert_equal MyOp.global.inspect, %{[:call, :model]}
  end

  #---
  #- step, pass, fail

  # Test: step/pass/fail
  # * do they deviate properly?
  class Create < Trailblazer::Operation
    step :decide!
    pass :wasnt_ok!
    pass :was_ok!
    fail :return_true!
    left :return_false!

    step :bla, input: ->(ctx, *) { {id: ctx.inspect} }, output: ->(scope, ctx) { ctx["hello"] = scope["1"]; ctx }

    def bla(ctx, id:1, **)
      puts id
      true
    end

    def decide!(options, decide: raise, **)
      options["a"] = true
      decide
    end

    def wasnt_ok!(options, **)
      options["y"] = false
    end

    def was_ok!(options, **)
      options["x"] = true
    end

    def return_true!(options, **); options["b"] = true end

    def return_false!(options, **); options["c"] = false end
  end

  it { Create.(decide: true).inspect("a", "x", "y", "b", "c").must_equal %{<Result:true [true, true, false, nil, nil] >} }
  it { Create.(decide: false).inspect("a", "x", "y", "b", "c").must_equal %{<Result:false [true, nil, nil, true, false] >} }
  it { Create.(decide: nil).keys.must_equal(%i(decide a b c)) }
  it { Create.(decide: nil).to_hash.must_equal(decide: nil, a: true, b: true, c: false) }
  #---
  #- trace

  it do
  end

  #---
  #- empty class
  class Noop < Trailblazer::Operation
  end

  it { Noop.().inspect("params").must_equal %{<Result:true [nil] >} }
  it { Noop.().keys.must_equal([]) }
  it { Noop.().to_hash.must_equal({}) }

  #---
  #- pass
  #- fail
  class Update < Trailblazer::Operation
    pass ->(options, **) { options["a"] = false }
    step ->(options, params: raise, **) { options["b"] = params[:decide] }
    fail ->(options, **) { options["c"] = true }
  end

  it { Update.("params" => {decide: true}).inspect("a", "b", "c").must_equal %{<Result:true [false, true, nil] >} }
  it { Update.("params" => {decide: false}).inspect("a", "b", "c").must_equal %{<Result:false [false, false, true] >} }

  #---
  #- inheritance
  class Upsert < Update
    step ->(options, **) { options["d"] = 1 }
  end

  class Unset < Upsert
    step ->(options, **) { options["e"] = 2 }
  end

  class Aliases < Update
    def self.flow_options_for_public_call(*)
      {
        context_options: {
          aliases: { 'b' => :settle },
          container_class: Trailblazer::Context::Container::WithAliases,
        }
      }
    end
  end

  it "allows to inherit" do
    Upsert.("params" => {decide: true}).inspect("a", "b", "c", "d", "e").must_equal %{<Result:true [false, true, nil, 1, nil] >}
    Unset. ("params" => {decide: true}).inspect("a", "b", "c", "d", "e").must_equal %{<Result:true [false, true, nil, 1, 2] >}
  end

  #---
  #- ctx container
  it do
    options = { "params" => {decide: true} }

    # Default call
    result = Update.(options)
    result.inspect("a", "b", "c").must_equal %{<Result:true [false, true, nil] >}

    # Circuit interface call
    signal, (ctx, _) = Update.([Update.options_for_public_call(options), {}], **{})

    signal.inspect.must_equal %{#<Trailblazer::Activity::Railway::End::Success semantic=:success>}
    assert_equal ctx.inspect, %(#<Trailblazer::Context::Container wrapped_options=#{{"params" => {:decide=>true}}} mutable_options=#{{"a" => false, "b" => true}}>)

    # Call by passing aliases as an argument.
    # This uses {#call}'s second positional argument.
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0.0")
      result = Update.(
        options,
        {
          context_options: {
            aliases: { 'b' => :settle },
            container_class: Trailblazer::Context::Container::WithAliases,
          }
        }
      )
    else
      result = Update.call_with_flow_options(
        options,
        {
          context_options: {
            aliases: { 'b' => :settle },
            container_class: Trailblazer::Context::Container::WithAliases,
          }
        },
      )
    end

    result[:settle].must_equal true
    # Set aliases by overriding `flow_options` at the compile time.
    result = Aliases.(options)
    result[:settle].must_equal true
  end
end
