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

  it "invokes with the taskWrap" do
    operation = Class.new(Trailblazer::Operation) do
      include Trailblazer::Activity::Testing.def_steps(:a)

      def self.add_1(wrap_ctx, original_args)
        ctx, = original_args[0]
        ctx[:seq] << 1
        return wrap_ctx, original_args # yay to mutable state. not.
      end

      merge = [
        [Trailblazer::Activity::TaskWrap::Pipeline.method(:insert_before), "task_wrap.call_task", ["user.add_1", method(:add_1)]]
      ]

      step :a, extensions: [Trailblazer::Activity::TaskWrap::Extension(merge: merge)]
    end

    # normal operation invocation
    result = operation.(seq: [])

    result.inspect(:seq).must_equal %{<Result:true [[1, :a]] >}

    # with tracing
    result = operation.trace(seq: [])

    result.inspect(:seq).must_equal %{<Result:true [[1, :a]] >}

    result.wtf?
  end
end
