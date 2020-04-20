$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/operation"

require "pp"

require "minitest/autorun"
require "trailblazer/activity/testing"
require "trailblazer/developer/render/linear"

Minitest::Spec.class_eval do
  Activity = Trailblazer::Activity
  T = Activity::Testing
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
