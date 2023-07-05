require "test_helper"

class CustomOutputTest < Minitest::Spec
  # #success passes fast.
  class Execute < Trailblazer::Operation
    UsePaypal = Class.new(Trailblazer::Activity::Signal)

    step :find_provider, Output(UsePaypal, :paypal) => End(:paypal)
    step :charge_creditcard

    def find_provider(ctx, params:, **)
      return true unless params[:provider] == :paypal
      UsePaypal
    end

    def charge_creditcard(ctx, **)
      ctx[:charged] = true
    end
  end

  describe "if a custom output is used in an operation" do
    it "adds `<custom_output>?` method to the result object which returns true if the operation takes the correspondent track" do
      result = Execute.(params: {provider: :paypal})
      assert result.paypal?
      assert !result.success?
      assert !result.failure?
      refute_respond_to result, :papa_johns?

      result = Execute.(params: {provider: :not_paypal})
      assert !result.paypal?
      assert result.success?
      assert !result.failure?
    end
  end

end
