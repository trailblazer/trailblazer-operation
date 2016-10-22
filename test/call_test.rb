require "test_helper"

# DISCUSS: do we need this test?
class CallTest < Minitest::Spec
  describe "::call" do
    class Create < Trailblazer::Operation
      def initialize(params, *dependencies) # dependencies could be a container, e.g. Dry::Container.
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

    it { Create.({})[:operation].inspect.must_equal "{} [<Skill {} {}>]" }
    it { Create.(name: "Jacob")[:operation].inspect.must_equal "{:name=>\"Jacob\"} [<Skill {} {}>]" }
    it { Create.({ name: "Jacob" }, { policy: Object })[:operation].inspect.must_equal "{:name=>\"Jacob\"} [<Skill {:policy=>Object} {}>]" }
  end
end

