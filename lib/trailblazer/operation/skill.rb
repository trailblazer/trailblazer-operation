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

  # replace the incoming options with a Skill instance.
  Skill::Build = ->(klass, options) { options[:skills] = Trailblazer::Skill.new(mutual={}, options[:skills], *options[:dependencies], klass.skills); klass } # FIXME: if we could, i'd return options[:skills] directly to replace the options object.
end
