require "test_helper"

class CallTest < Minitest::Spec
  describe "::call" do
    class Create < Trailblazer::Operation
    end

    it { Create.().must_be_instance_of Create }
  end
end
