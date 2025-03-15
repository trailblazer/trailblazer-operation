require "test_helper"

class ActivityInterfaceTest < Minitest::Spec
  require "trailblazer/operation/testing"
  include Trailblazer::Operation::Testing::Assertions

  let (:operation) do
    Class.new(Trailblazer::Operation) do
      step :model, Output(:failure) => End(:not_found)
      step :validate
      step :save

      include T.def_steps(:model, :validate, :save)
    end
  end

  it "exposes the step DSL" do
    assert_call(operation, seq: "[:model, :validate, :save]")
    assert_call(operation, seq: "[:model]", model: false, terminus: :not_found)
    assert_call(operation, seq: "[:model, :validate]", validate: false, terminus: :failure)
  end

  it "we can nested operations" do
    nested = self.operation

    operation = Class.new(Trailblazer::Operation) do
      step Subprocess(nested), Output(:not_found) => End(:fail_fast)
      step :persist

      include T.def_steps(:persist)
    end

    assert_call operation, seq: "[:model, :validate, :save, :persist]"
    assert_call operation, seq: "[:model]", model: false, terminus: :fail_fast
  end
end
