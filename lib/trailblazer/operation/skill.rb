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

    def call(params={}, options={}, *containers)
      skills = Trailblazer::Skill.new({}, options, self.skills, *containers) # DISCUSS: first arg are the mutable options.
      super(params, skills)
    end
  end

  def self.included(includer)
    includer.extend ClassMethods
  end
end
