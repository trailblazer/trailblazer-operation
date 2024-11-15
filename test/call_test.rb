  require "test_helper"

class CallTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(*) { true }
    def inspect
      @skills.inspect.to_s
    end
  end

  it { Create.().must_be_instance_of Trailblazer::Operation::Railway::Result }

  # it { Create.({}).inspect.must_equal %{<Result:true <Skill {} {\"params\"=>{}} {\"pipetree\"=>[>operation.new]}> >} }
  # it { Create.(name: "Jacob").inspect.must_equal %{<Result:true <Skill {} {\"params\"=>{:name=>\"Jacob\"}} {\"pipetree\"=>[>operation.new]}> >} }
  # it { Create.({ name: "Jacob" }, { policy: Object }).inspect.must_equal %{<Result:true <Skill {} {:policy=>Object, \"params\"=>{:name=>\"Jacob\"}} {\"pipetree\"=>[>operation.new]}> >} }

  #---
  # success?
  class Update < Trailblazer::Operation
    step ->(ctx, **) { ctx[:result] }
  end

  # operation success
  it do
    result = Update.(result: true)

    result.success?.must_equal true

    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Success
    result.event.must_equal Update.to_h[:outputs][0].signal
  end

  # operation failure
  it do
    result = Update.(result: false)

    result.success?.must_equal false
    result.failure?.must_equal true

    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Failure
    result.event.must_equal Update.to_h[:outputs].find { |output| output.semantic == :failure }.signal
  end

  def self.add_1(wrap_ctx, original_args)
    ctx, = original_args[0]
    ctx[:seq] << 1
    return wrap_ctx, original_args # yay to mutable state. not.
  end

  it "invokes with the taskWrap" do
    operation = Class.new(Trailblazer::Operation) do
      include Trailblazer::Activity::Testing.def_steps(:a)

      merge = [
      ]

      step :a, extensions: [Trailblazer::Activity::TaskWrap::Extension.WrapStatic(
          [CallTest.method(:add_1), prepend: "task_wrap.call_task", id: "user.add_1"]
        )]
    end

    # normal operation invocation
    result = operation.(seq: [])

    result.inspect(:seq).must_equal %{<Result:true [[1, :a]] >}

    # with tracing
    result = operation.wtf?(seq: [])

    result.inspect(:seq).must_equal %{<Result:true [[1, :a]] >}
  end


  it "calls with the taskWrap defined for operation using circuit interface" do
    operation = Class.new(Trailblazer::Operation) do
      include Trailblazer::Activity::Testing.def_steps(:a)

      step :a
    end

    my_extension = Trailblazer::Activity::TaskWrap::Extension(
      [CallTest.method(:add_1), id: "my.add_1", append: "task_wrap.call_task"]
    )

    # circuit interface invocation using call
    signal, (ctx, _) = operation.call(
      [{seq: []}, {}],
      wrap_runtime: Hash.new(my_extension),
      runner: Trailblazer::Activity::TaskWrap::Runner
    )

    assert_equal signal.to_h[:semantic], :success
    assert_equal ctx[:seq], [1, :a, 1, 1]
  end
end
