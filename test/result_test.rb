require "test_helper"


require "dry-matcher"
module Trailblazer::Operation::Result
end

class ResultTest < Minitest::Spec
  # provide standard outcomes, such as :success.
  Matcher = Dry::Matcher.new(
    success: Dry::Matcher::Case.new(
      match: -> value { value[:status] == :ok },
      resolve: -> value { value }
    # , failure: failure_case
  )
)


  class Create < Trailblazer::Operation
    # Trailblazer#result[:message] = _t("Please log in, Regulator!")
    # Trailblazer::result :@message # adds to result after Operation#call.

    def call(**)
      { status: :ok, model: Object, operation: self }
    end
  end

  it "what" do
    res = Create.()

    result = Matcher.(res) do |m|
      m.success { |v| raise "Yay: #{v}" }

      # m.failure :not_found do |v|
      #   raise "Oops, not found: #{v}"
      # end
    end
  end
end
