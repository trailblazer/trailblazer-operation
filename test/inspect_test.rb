require "test_helper"


class InspectTest < Minitest::Spec
  # Test: #to_table
  class Create < Trailblazer::Operation
    step :decide!
    pass :wasnt_ok!
    pass :was_ok!
    fail :return_true!
    fail :return_false!
    step :finalize!
  end

  #---
  #- to_table

  # pp Create.instance_variable_get(:@builder)

  it do
    Trailblazer::Operation.introspect(Create).must_equal %{[>decide!,>>wasnt_ok!,>>was_ok!,<<return_true!,<<return_false!,>finalize!]}
  end

  it do
    Trailblazer::Operation::Inspect.call(Create, style: :rows).must_equal %{
 0 ==============================>decide!
 1 ===========================>>wasnt_ok!
 2 =============================>>was_ok!
 3 <<return_true!========================
 4 <<return_false!=======================
 5 ============================>finalize!}
  end

  describe "step with only one output (happens with Nested)" do
    class Present < Trailblazer::Operation
      pass :ok!, outputs: {:success => Trailblazer::Activity::Output("signal", :success)}
    end

    it do
      Trailblazer::Operation.introspect(Present).must_equal %{[>>ok!]}
    end
  end
end
