require "minitest/autorun"

require "trailblazer/operation"
require "trailblazer/core"

Minitest::Spec.class_eval do
  include Trailblazer::Core::Utils::AssertRun
  include Trailblazer::Core::Utils::AssertEqual
  T = Trailblazer::Core
end
