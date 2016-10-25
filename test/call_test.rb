require "test_helper"

# DISCUSS: do we need this test?
class CallTest < Minitest::Spec
  describe "::call" do
    class Create < Trailblazer::Operation
      def inspect
        "#{@instance_attrs.inspect}"
      end
    end

    # in 1.2, ::() returns op instance.
    it { Create.().must_be_instance_of Create }

    it { Create.({}).inspect.must_equal "<Skill {:valid=>true} {\"params\"=>{}} {\"pipetree\"=>[Skill::Build|>New|>Call]}>" }
    it { Create.(name: "Jacob").inspect.must_equal "<Skill {:valid=>true} {\"params\"=>{:name=>\"Jacob\"}} {\"pipetree\"=>[Skill::Build|>New|>Call]}>" }
    it { Create.({ name: "Jacob" }, { policy: Object }).inspect.must_equal "<Skill {:valid=>true} {:policy=>Object, \"params\"=>{:name=>\"Jacob\"}} {\"pipetree\"=>[Skill::Build|>New|>Call]}>" }
  end
end

