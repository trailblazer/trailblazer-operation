require "test_helper"

require "trailblazer/competences"


  def contract(name=:default)
    # if nothing passed, return
    @contract ||= competence["contract.class"].new

  end

class CompetencesTest < Minitest::Spec
  Competences = Trailblazer::Competences
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


  describe "Competences" do
    it do
      class_level_container = Competences::Container.new
      class_level_container["contract.class"] = Competences::Build.new.(Object) # Create::contract Contract::Create
      class_level_container["model.class"] = String

      runtime_competences = { "contract" => MyContract=Class.new, "model.class" => Integer }

      competences = Competences.new(runtime_competences, class_level_container)

      # from runtime.
      competences["contract"].must_equal MyContract
      # from compile-time.
      competences["contract.class"].class.superclass.must_equal Object
      # runtime supersedes compile-time.
      competences["model.class"].must_equal Integer

      competences["model.class"] = Fixnum
      competences["model.class"].must_equal Fixnum
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

