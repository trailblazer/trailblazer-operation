require "test_helper"

module A
  class DocsResultTest < Minitest::Spec
    Memo = Class.new
    module Memo::Operation
      class Create < Trailblazer::Operation
        step :validate, Output(:failure) => End(:validation_error)
        step :save
        include T.def_steps(:validate, :save)
      end
    end

    it "exposes {#terminus}" do
      result = Memo::Operation::Create.(seq: [])
      assert_equal result.terminus.to_h.inspect, %({:semantic=>:success})

      result = Memo::Operation::Create.(validate: false, seq: [])
      assert_equal result.terminus.to_h.inspect, %({:semantic=>:validation_error})

      result = Memo::Operation::Create.(save: false, seq: [])
      assert_equal result.terminus.to_h.inspect, %({:semantic=>:failure})
    end

    it "deprecates Result#event" do
      result = Memo::Operation::Create.(seq: [])
      terminus = nil

      _, warning = capture_io do
        terminus = result.event
      end
      line_no = __LINE__ - 2

      assert_equal warning, %{[Trailblazer] #{File.realpath(__FILE__)}:#{line_no} Using `Result#event` is deprecated, please use `Result#terminus`\n}
      assert_equal terminus.to_h.inspect, %({:semantic=>:success})
    end
  end
end
