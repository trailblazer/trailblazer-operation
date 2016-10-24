require "trailblazer/skill"
require "uber/delegates"

# Dependency ("skill") management for Operation.
# Op::[]
# Op::[]=
# Writing, even with an existing name, will never mutate a container.
# Op#[]
# Op#[]=
# Op.(params, { "constructor" => competences })
class Trailblazer::Operation
  # Operation::[], ::[]=.

  module Skill
    module Accessors
      # This is private API.
      def skills
        @skills ||= {}
      end

      extend Uber::Delegates
      delegates :skills, :[], :[]=
    end

    #   def call(params={}, options={}, *containers)
    #     skills = Trailblazer::Skill.new({}, options, self.skills, *containers) # DISCUSS: first arg are the mutable options.
    #     super(params, skills)
    #   end
    # end

    def self.included(includer)
      # includer.extend ClassMethods
      includer.| Build, prepend: true # run the skill logic before everything else.
    end
  end

  Skill::Build = ->(klass, args) {
    args[:skills] = Trailblazer::Skill.new(mutual={}, args, klass.skills); klass }
end
