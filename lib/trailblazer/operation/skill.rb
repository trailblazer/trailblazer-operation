require "trailblazer/skill"

# Dependency ("skill") management for Operation.
# Op::[]
# Op::[]=
# Writing, even with an existing name, will never mutate a container.
# Op#[]
# Op#[]=
# Op.(params, { "constructor" => competences })
module Trailblazer::Operation::Skill
  module ClassMethods
    # This is private API.
    def skills
      @skills ||= {}
    end

    # class-level skills.
    require "uber/delegates"
    extend Uber::Delegates
    delegates :skills, :[], :[]=

    def call(params={}, options={})
      skills = Trailblazer::Skill.new(options, self.skills)
      super(params, skills)
    end
  end

  def self.included(includer)
    includer.extend ClassMethods
  end

  # def initialize(params, instance_attrs={})
  #   # the operation instance will now find runtime-skills first, then classlevel skills.
  #   skills = Trailblazer::Skill.new(instance_attrs, self.class.skills) # DISCUSS: alternatively, we could prepare this hash in ::build_operation, on the outside.

  #   super(params, skills)
  # end
end
