require "test_helper"

class InstanceAttrTest < Minitest::Spec
  class Create < Trailblazer::Operation
  end

  # no dependencies provided.
  it { Create.()[:operation].send(:[], :not_existent).must_equal nil }
  # dependencies provided.
  it { Create.({}, contract: Object)[:operation].send(:[], :not_existent).must_equal nil }
  it { Create.({}, contract: Object)[:operation].send(:[], :contract).must_equal Object }
end

# {
#   user_repository: ..,
#   current_user: ..,
# }


# 1. initialize(params, {})
# 2. extend AutoInject[] shouldn't override constructor but simply pass injected dependencies in second arg (by adding dependencies to hash).
