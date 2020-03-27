require "test_helper"

class DocsClassFieldsTest < Minitest::Spec
  module A
    class AlwaysTrue
      def self.call(params)
        true
      end
    end


    class Insert < Trailblazer::Operation
      extend ClassDependencies

      self[:name] = :insert
    end

    #:create
    class Create < Trailblazer::Operation
      extend ClassDependencies

      # Configure some dependency on class level
      self[:validator] = AlwaysTrue

      step :validate
      step Subprocess(Insert)

      #:validate
      def validate(ctx, validator:, params:, **)
        validator.(params)
      end
      #:validate end
    end
    #:create end
  end

  it "what" do
    Create = A::Create

    ctx = {params: {name: "Yogi"}}

    #:invoke
    signal, (ctx, _) = Create.([ctx, {}])

    puts ctx[:validator] #=> AlwaysTrue
    #:invoke end

    puts ctx[:name]      #=> insert

    signal.inspect.must_equal %{#<Trailblazer::Activity::Railway::End::Success semantic=:success>}
    ctx[:validator].inspect.must_equal %{DocsClassFieldsTest::A::AlwaysTrue}
    ctx[:name].inspect.must_equal %{:insert}
  end
end
