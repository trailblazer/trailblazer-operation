require "test_helper"
require "trailblazer/operation/invalid"

class InvalidTest < Minitest::Spec
  describe "#invalid!" do
    class Delete < Trailblazer::Operation
      include Invalid

      def process(invalid:)
        invalid! if invalid
      end
    end

    it { Delete.(invalid: false)["valid"].must_equal true }
    it { Delete.(invalid: true)["valid"].must_equal false }
  end
end
