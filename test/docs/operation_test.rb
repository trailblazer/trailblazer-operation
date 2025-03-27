require "test_helper"

class DocsActivityTest < Minitest::Spec
  Memo = Struct.new(:text)

  #:memo
  module Memo::Operation
    class Create < Trailblazer::Operation
      step :create_model

      def create_model(ctx, params:, **)
        ctx[:model] = Memo.new(params[:text])
      end
    end
  end
  #:memo end

  describe Memo::Operation::Create do
    it "allows indifferent access for ctx keys" do
      #:ctx-indifferent-access
      result = Memo::Operation::Create.(params: { text: "Enjoy an IPA" })

      result[:params]     # => { text: "Enjoy an IPA" }
      result['params']    # => { text: "Enjoy an IPA" }
      #:ctx-indifferent-access end

      assert_equal result.success?, true
      assert_equal result[:params],({ text: "Enjoy an IPA" })
      assert_equal result["params"], ({ text: "Enjoy an IPA" })
    end
  end
end
