require "test_helper"

class CallTest < Minitest::Spec
  describe "::call" do
    class Create < Trailblazer::Operation
    end

    # in 1.2, ::() returns op instance.
    it { Create.()[:operation].must_be_instance_of Create }
  end

  describe "#invalid!" do
    class Delete < Trailblazer::Operation
      def process(invalid:, **params)
        invalid! if invalid
      end
    end

    it { Delete.(params: {invalid: false})[:valid].must_equal true }
    it { Delete.(params: {invalid: true})[:valid].must_equal false }
  end
end

