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
    it { Create.().must_be_instance_of Create }

    it { Create.({}).inspect.must_equal "{} [<Skill {:valid=>true} {} {}>]" }
    it { Create.(name: "Jacob").inspect.must_equal "{:name=>\"Jacob\"} [<Skill {:valid=>true} {} {}>]" }
    it { Create.({ name: "Jacob" }, { policy: Object }).inspect.must_equal "{:name=>\"Jacob\"} [<Skill {:valid=>true} {:policy=>Object} {}>]" }
  end
end

