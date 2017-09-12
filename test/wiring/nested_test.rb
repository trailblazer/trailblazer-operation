require "test_helper"

class WiringWithNestedTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step task: Trailblazer::Activity::Nested( Edit, call: :__call__ ), node_data: { id: "Nested/" }, outputs: Edit.outputs
    step :b
    fail :f
  end
end
