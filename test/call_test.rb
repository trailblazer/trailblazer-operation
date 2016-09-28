require "test_helper"

class CallTest < Minitest::Spec
  describe "::call" do
    class Create < Trailblazer::Operation
    end

    # in 1.2, ::() returns op instance.
    it { Create.()[:operation].must_be_instance_of Create }
  end
end
