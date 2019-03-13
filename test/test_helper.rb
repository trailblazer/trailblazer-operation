require "pp"

require "minitest/autorun"
require "trailblazer/operation"

Minitest::Spec.class_eval do
  Activity = Trailblazer::Activity
end
