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

  it "we can use public call" do
    result = Trailblazer::Operation.({seq: []})

    assert_equal result.success?, true
    assert_equal result.send(:data).class, Trailblazer::Context::Container#::WithAliases
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

  def self.flow_options_with_aliasing
    {
      context_options: {
        aliases: {"seq" => :sequence},
        container_class: Trailblazer::Context::Container::WithAliases,
      }
    }
  end

  # test Op.wtf?
  it "{Operation.wtf?}" do
    operation_class = Class.new(Trailblazer::Operation)
    operation_class.configure! do
      {
        flow_options: OperationTest.flow_options_with_aliasing
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
    assert_equal result.send(:data).class, Trailblazer::Context::Container::WithAliases
  end
  # test matcher block interface

  # TODO: test overriding configure! options etc in subclasses
  it "inheritance: configure! can be overridden per class" do
    operation_class_1 = Class.new(Trailblazer::Operation)
    operation_class_1.configure! { {flow_options: OperationTest.flow_options_with_aliasing} }

    # override configure
    operation_class_2 = Class.new(operation_class_1)
    operation_class_2.configure! { {} }

    # inherit configure
    operation_class_3 = Class.new(operation_class_1)


    result   = Trailblazer::Operation.(seq: {id: 1})
    result_1 = operation_class_1.(seq: {id: 1})
    result_2 = operation_class_2.(seq: {id: 1})
    result_3 = operation_class_3.(seq: {id: 1})

    assert_equal result.success?, true
    assert_equal result.keys.inspect, "[:seq]"
    assert_equal result_1.success?, true
    assert_equal result_1.keys.inspect, "[:seq, :sequence]"
    assert_equal result_2.success?, true
    assert_equal result_2.keys.inspect, "[:seq]"
    assert_equal result_3.success?, true
    assert_equal result_3.keys.inspect, "[:seq, :sequence]"
  end

  it "Operation.call accepts block matcher interface" do

  end


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
    assert_result result, {params: {}, model: true, current_user: Object, capture_circuit_options: "[:exec_context, :wrap_runtime, :activity, :runner]"}
  end
end
