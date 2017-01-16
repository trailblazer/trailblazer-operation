require "test_helper"

# DISCUSS: do we need this test?
class CallTest < Minitest::Spec
  describe "::call" do
    class Create < Trailblazer::Operation
      def inspect
        "#{@skills.inspect}"
      end
    end

    it { Create.().must_be_instance_of Trailblazer::Operation::Result }

    it { Create.({}).inspect.must_equal %{<Result:true <Skill {} {\"params\"=>{}} {\"pipetree\"=>[>operation.new]}> >} }
    it { Create.(name: "Jacob").inspect.must_equal %{<Result:true <Skill {} {\"params\"=>{:name=>\"Jacob\"}} {\"pipetree\"=>[>operation.new]}> >} }
    it { Create.({ name: "Jacob" }, { policy: Object }).inspect.must_equal %{<Result:true <Skill {} {:policy=>Object, \"params\"=>{:name=>\"Jacob\"}} {\"pipetree\"=>[>operation.new]}> >} }

    #---
    # success?
    class Update < Trailblazer::Operation
      step ->(options) { options["params"] }, after: "operation.new"
    end

    it { Update.(true).success?.must_equal true }
    it { Update.(false).success?.must_equal false }
  end
end

