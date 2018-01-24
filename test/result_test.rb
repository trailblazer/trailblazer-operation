  require "test_helper"

class RailwayResultTest < Minitest::Spec
  Result  = Trailblazer::Operation::Railway::Result
  Success = Trailblazer::Operation::Railway::End::Success

  let(:event)    { Success.new(semantic: nil) }
  let (:success) { Result.new(true, { "x"=> String }, event) }

  it { success.success?.must_equal true }
  it { success.failure?.must_equal false }
  it { success.event.must_equal event }

  # it { success["success?"].must_equal true }
  # it { success["failure?"].must_equal false }
  it { success["x"].must_equal String }
  it { success["not-existant"].must_be_nil }
  it { success.slice("x").must_equal [String] }

  #---
  # inspect
  it { success.inspect.must_equal %{<Result:true {\"x\"=>String} >} }
  it { Result.new(true, { "x"=> true, "y"=>1, "z"=>2 }, event).inspect("z", "y").must_equal %{<Result:true [2, 1] >} }

  class Create < Trailblazer::Operation
    success :call

    def call(options, **)
      options[:message] = "Result objects are actually quite handy!"
    end
  end

  # #result[]= allows to set arbitrary k/v pairs.
  it { Create.()[:message].must_equal "Result objects are actually quite handy!" }
end
