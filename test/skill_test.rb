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

      skill = Trailblazer::Skill.new(runtime_skills, class_level_container)

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

      # original container don't get changed
      class_level_container.inspect.must_equal %{{"contract.class"=>Object, "model.class"=>String}}
      runtime_skills.inspect.must_equal %{{"contract"=>SkillTest::MyContract, "model.class"=>Integer}}

      # setting false.
      skill[:valid] = false
      skill[:valid].must_equal false

      # setting nil.
      skill[:valid] = nil
      skill[:valid].must_equal nil
    end
  end
end
