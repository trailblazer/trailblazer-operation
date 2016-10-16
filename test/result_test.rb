require "test_helper"
require "dry-matcher"
module Trailblazer::Operation::Result
end

class ResultTest < Minitest::Spec
  # provide standard outcomes, such as :success.
  Matcher = Dry::Matcher.new(
    success: Dry::Matcher::Case.new(
      match:   ->(result) { result[:valid] == true },
      resolve: ->(result) { result }
    # , failure: failure_case
  )
)


  class Create < Trailblazer::Operation
    # Trailblazer#result[:message] = _t("Please log in, Regulator!")
    # Trailblazer::result/::expose :@message # adds to result after Operation#call.

    def process(*)
      result[:message] = "Result objects are actually quite handy!"
    end
  end

  # #result[]= allows to set arbitrary k/v pairs.
  it { Create.()[:message].must_equal "Result objects are actually quite handy!" }

  it "what" do
    res = Create.()
    asserted = nil

    result = Matcher.(res) do |m|
      m.success { |v| asserted = "valid is true" }

      # m.failure :not_found do |v|
      #   raise "Oops, not found: #{v}"
      # end
    end

    asserted.must_equal "valid is true"
  end
end


# op --> http
# ok --> 200
# created --> 201 (?)
# unauthorized --> 401


# Create.() => Create.new.() # so it works with dry .new.(), eventually
# do we want #call or the "old" #process?
