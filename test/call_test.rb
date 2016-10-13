require "test_helper"

class CallTest < Minitest::Spec
  describe "::call" do
    class Create < Trailblazer::Operation
      def initialize(params, **dependencies) # dependencies could be a container, e.g. Dry::Container.
        super
        @params       = params
        @dependencies = dependencies
      end

      def inspect
        "#{@params} #{@dependencies}"
      end
    end

    # in 1.2, ::() returns op instance.
    it { Create.()[:operation].must_be_instance_of Create }

    it { Create.({})[:operation].inspect.must_equal "{} {}" }
    it { Create.(name: "Jacob")[:operation].inspect.must_equal "{:name=>\"Jacob\"} {}" }
    it { Create.({ name: "Jacob" }, { policy: Object })[:operation].inspect.must_equal "{:name=>\"Jacob\"} {:policy=>Object}" }
  end

  describe "#invalid!" do
    class Delete < Trailblazer::Operation
      def process(invalid:, **)
        invalid! if invalid
      end
    end

    it { Delete.(invalid: false)[:valid].must_equal true }
    it { Delete.(invalid: true)[:valid].must_equal false }
  end
end

