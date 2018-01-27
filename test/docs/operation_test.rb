require "test_helper"

class DocsActivityTest < Minitest::Spec
  Memo = Struct.new(:body)

  class Memo::Create < Trailblazer::Operation
    step :create_model
    def create_model(ctx, params:, **)
      ctx[:model] = Memo.new(params[:body])
    end
  end

  #:describe
  describe Memo::Create do
    it "creates a sane Memo instance" do
      result = Memo::Create.( params: { body: "Enjoy an IPA" } )

      result.success?.must_equal true
      result[:model].body.must_equal "Enjoy an IPA"
    end
  end
  #:describe end
end
