require "pp"

require "minitest/autorun"
require "trailblazer/operation"

Minitest::Spec::Activity = Trailblazer::Activity

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

  # builder for PlusPoles
  def self.plus_poles_for(mapping)
    ary = mapping.collect { |evt, semantic| [Trailblazer:: Activity::Output(evt, semantic), semantic ] }

    Trailblazer::Activity::Magnetic::DSL::PlusPoles.new.merge(::Hash[ary])
  end
end

Minitest::Spec.class_eval do
  Activity = Trailblazer::Activity
end
