require "test_helper"

class ResultTest < Minitest::Spec
  Result = Trailblazer::Operation::Result
  let (:success) { Result.new(true, "x"=> String) }
  it { success.success?.must_equal true }
  it { success.failure?.must_equal false }
  # it { success["success?"].must_equal true }
  # it { success["failure?"].must_equal false }
  it { success["x"].must_equal String }
  it { success["not-existant"].must_equal nil }
  it { success.slice("x").must_equal [String] }

  #---
  # inspect
  it { success.inspect.must_equal %{<Result:true {\"x\"=>String} >} }
  it { Result.new(true, "x"=> true, "y"=>1, "z"=>2).inspect("z", "y").must_equal %{<Result:true [2, 1] >} }

  class Create < Trailblazer::Operation
    success :call

    def call(*)
      self[:message] = "Result objects are actually quite handy!"
    end
  end

  # #result[]= allows to set arbitrary k/v pairs.
  it { Create.()[:message].must_equal "Result objects are actually quite handy!" }
end
