require "test_helper"
require "trailblazer/skill"

class SkillTest < Minitest::Spec
  describe "Skill" do
    it do
      class_level_container = {
        "contract.class" => Object,
        "model.class" => String
      }

      runtime_skills = {
        "contract" => MyContract=Class.new,
        "model.class" => Integer
      }

      mutable_options = {}

      skill = Trailblazer::Skill.new(mutable_options, runtime_skills, class_level_container)

      # non-existent key.
      skill[:nope].must_equal nil

      # from runtime.
      skill["contract"].must_equal MyContract
      # from compile-time.
      skill["contract.class"].must_equal Object
      # runtime supersedes compile-time.
      skill["model.class"].must_equal Integer

      skill["model.class"] = Fixnum
      skill["model.class"].must_equal Fixnum

      # add new tuple.
      skill["user.current"] = "Todd"

      # options we add get added to the hash.
      mutable_options.inspect.must_equal %{{"model.class"=>Fixnum, "user.current"=>"Todd"}}
      # original container don't get changed
      class_level_container.inspect.must_equal %{{"contract.class"=>Object, "model.class"=>String}}
      runtime_skills.inspect.must_equal %{{"contract"=>SkillTest::MyContract, "model.class"=>Integer}}
    end
  end
end
# resolve: prefer @instance_attrs over competences
#   or instace_atrt is competences

# dependencies = { current_user: Runtime::User..., container: BLA }
# dependencies[:current_user]
# dependencies["user.create.contract"] # delegates to container, somehow.

# Create.(params, dependencies) # not sure if op should build this runtime dependencies hash or if it comes from outside.

