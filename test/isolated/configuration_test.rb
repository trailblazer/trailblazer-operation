require "test_helper"

class ConfigurationTest < Minitest::Spec
  it "Operation.call works without any configuration" do
    result = Trailblazer::Operation.(params: {})

    assert_equal result.success?, true
    assert_equal result[:params], {}
    assert_nil result[:parameters]

  # circuit-interface works.
    signal, (result, _) = Trailblazer::Operation.([{params: {}}, {}])

    assert_equal signal.to_h[:semantic], :success
    assert_equal result[:params], {}
    assert_nil result[:parameters]

  # we can overwrite Operation.__()
    Trailblazer::Operation.configure! do
      {
        flow_options: {
          context_options: {
            aliases: { "params" => :parameters },
            container_class: Trailblazer::Context::Container::WithAliases,
          }
        }
      }
    end

  # and now, we got aliasing on Operation and subclasses.
    result = Trailblazer::Operation.(params: {id: 1})
    assert_aliasing(result)

  # subclasses also work
    result = Class.new(Trailblazer::Operation).(params: {id: 1})
    assert_aliasing(result)
  end

  def assert_aliasing(result)
    assert_equal result.success?, true
    assert_equal result[:params], {id: 1}
    assert_equal result[:parameters], {id: 1}
  end
end
