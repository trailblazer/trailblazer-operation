require "trailblazer/skill"

# Dependency ("skill") management for Operation.
# Op::[]
# Op::[]=
# Op#[]
# Op#[]=
# Op.(params, { "constructor" => competences })
module Trailblazer::Operation::Skill
  module ClassMethods
    # This is private API.
    def skills
      @skills ||= {}
    end

    require "uber/delegates"
    extend Uber::Delegates
    delegates :skills, :[], :[]=
  end

  def self.included(includer)
    includer.extend ClassMethods
  end

  def initialize(params, instance_attrs={})
    # the operation instance will now find runtime-skills first, then classlevel skills.
    skills = Trailblazer::Skill.new(instance_attrs, self.class.skills)

    super(params, skills)
  end
end
