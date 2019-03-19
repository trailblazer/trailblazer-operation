require "pp"

require "minitest/autorun"
require "trailblazer/operation"
require "trailblazer/activity/testing"

Minitest::Spec.class_eval do
  Activity = Trailblazer::Activity
end
