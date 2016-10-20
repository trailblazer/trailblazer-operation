require "test_helper"
require "trailblazer/skill"

class SkillTest < Minitest::Spec
  Skill = Trailblazer::Skill
  # it { Competence::Build.new.(Object) ->(*) { def } }

  # Resolver (do we need it?)
  # it do
  #   class_level_container = Competence::Container.new
  #   class_level_container["contract.class"] = Competence::Build.new.(Object) # Create::contract Contract::Create
  #   class_level_container["model.class"] = String


  #   runtime_competences = { "contract" => MyContract=Class.new, "model.class" => Integer }

  #   resolver = Competence::Resolver.new(runtime_competences, class_level_container)

  #   # from runtime.
  #   resolver["contract"].must_equal MyContract
  #   # from compile-time.
  #   resolver["contract.class"].class.superclass.must_equal Object
  #   # runtime supersedes compile-time.
  #   resolver["model.class"].must_equal Integer


  #   # Create["contract.class"] = .. # Create.contract_class = ..
  # end


  describe "Skill" do
    it do
      class_level_container = {}
      class_level_container["contract.class"] = Object # Create::contract Contract::Create
      class_level_container["model.class"] = String

      runtime_competences = { "contract" => MyContract=Class.new, "model.class" => Integer }

      skill = Skill.new(runtime_competences, class_level_container)

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
    end
  end
end
# resolve: prefer @instance_attrs over competences
#   or instace_atrt is competences



# def contract(constant=nil, &block)
#       return competence.container["contract.class"] unless constant or block_given?

#       # create the new competence class.
#       competence.container.from("contract.class", constant, &block)
#         # self.contract_class= Class.new(constant) if constant
#         # contract_class.class_eval(&block) if block_given?
#     end




# dependencies = { current_user: Runtime::User..., container: BLA }
# dependencies[:current_user]
# dependencies["user.create.contract"] # delegates to container, somehow.

# Create.(params, dependencies) # not sure if op should build this runtime dependencies hash or if it comes from outside.

