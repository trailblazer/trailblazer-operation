require "trailblazer/skill"

# Dependency ("skill") management for Operation.
class Trailblazer::Operation
  module Skill
    # The class-level skill container: Operation::[], ::[]=.
    module Accessors
      # :private:
      def skills
        @skills ||= {}
      end

      extend Forwardable
      def_delegators :skills, :[], :[]=
    end

    # Overrides Operation::call, creates the Skill hash and passes it to :call.
    module Call
      def call(params={}, options={}, *dependencies)
        options = options.merge("params" => params) # __call__ API.

        super Trailblazer::Skill.new(options, *dependencies, self.skills)
      end
    end # Call
  end
end
