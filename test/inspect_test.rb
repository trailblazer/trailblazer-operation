require "test_helper"


class InspectTest < Minitest::Spec
  # Test: #to_table
  class Create < Trailblazer::Operation
    step :decide!
    success :wasnt_ok!
    success :was_ok!
    failure :return_true!
    failure :return_false!
    step :finalize!
  end

  #---
  #- to_table

  it do
    Trailblazer::Operation::Inspect.call(Create).must_equal %{[>decide!,>wasnt_ok!,>was_ok!,<return_true!,<return_false!,>finalize!]}
  end

  it do
    Trailblazer::Operation::Inspect.call(Create, style: :rows).must_equal %{
 0 ==============================>decide!
 1 ============================>wasnt_ok!
 2 ==============================>was_ok!
 3 <return_true!=========================
 4 <return_false!========================
 5 ============================>finalize!}
  end
end
