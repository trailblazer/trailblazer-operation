require "test_helper"

class RailwayResultTest < Minitest::Spec
  Result  = Trailblazer::Operation::Railway::Result
  Success = Trailblazer::Operation::Railway::End::Success

  let(:terminus) { Success.new(semantic: nil) }
  let(:success)  { Result.new(true, {"x" => String}, terminus) }

  it { assert_equal success.success?, true }
  it { assert_equal success.failure?, false }
  it { assert_equal success.terminus, terminus }

  it { assert_equal success["x"], String }
  it { assert_nil success["not-existant"] }
  it { assert_equal success.to_h, {"x"=>String} }
  it { assert_equal success.keys, ["x"] }
end
