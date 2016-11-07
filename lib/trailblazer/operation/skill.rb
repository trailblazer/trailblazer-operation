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
  module Skill
    # The class-level skill container: Operation::[], ::[]=.
    module Accessors
      # :private:
      def skills
        @skills ||= {}
      end

      extend Uber::Delegates
      delegates :skills, :[], :[]=
    end

    # Overrides Operation::call, creates the Skill hash and passes it to :call.
    module Call
      def call(params={}, options={}, *dependencies)
        super Trailblazer::Skill.new(mutual={}, options.merge("params" => params), *dependencies, self.skills)
      end
    end
  end
end
