require "test_helper"
require "dry-matcher"

class ResultTest < Minitest::Spec
  let (:success) { Trailblazer::Operation::Result.new(true, "x"=> String) }
  it { success.success?.must_equal true }
  it { success.failure?.must_equal false }
  # it { success["success?"].must_equal true }
  # it { success["failure?"].must_equal false }
  it { success["x"].must_equal String }
  it { success["not-existant"].must_equal nil }
  it { success.slice("x").must_equal [String] }
  it { success.inspect.must_equal %{<Result:true {\"x\"=>String} >} }



  # provide standard outcomes, such as :success.
  Matcher = Dry::Matcher.new(
    success: Dry::Matcher::Case.new(
      match:   ->(result) { result.success? == true },
      resolve: ->(result) { result }
    # , failure: failure_case
  )
)


  class Create < Trailblazer::Operation
    def process(*)
      self[:message] = "Result objects are actually quite handy!"
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

