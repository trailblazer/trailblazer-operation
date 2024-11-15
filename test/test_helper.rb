require "minitest/autorun"

require "pp"
require "trailblazer/operation"

require "trailblazer/activity/testing"
require "trailblazer/developer/render/linear"
require "trailblazer/core"

Minitest::Spec.class_eval do
  T = Trailblazer::Activity::Testing
  include Trailblazer::Activity::Testing::Assertions
  CU = Trailblazer::Core::Utils

  def assert_equal(asserted, expected, *args)
    super(expected, asserted, *args)
  end

  def assert_result(result, variables, outcome: true)
    assert_equal result.success?, outcome

    # assert_equal result.send(:data).sort_by { |key,  _| key.to_s }.to_h.inspect, variables.sort_by { |key, _| key.to_s }.to_h.inspect
    assert_equal result.send(:data).to_h, variables
  end
end

# TODO: replace all this with {Activity::Testing.def_steps}
module Test
  # Create a step method in `klass` with the following body.
  #
  #   def a(options, a_return:, data:, **)
  #     data << :a
  #
  #     a_return
  #   end
  def self.step(klass, *names)
    names.each do |name|
      method_def =
        %{def #{name}(options, #{name}_return:, data:, **)
          data << :#{name}
          #{name}_return
        end}

      klass.class_eval(method_def)
    end
  end
end
