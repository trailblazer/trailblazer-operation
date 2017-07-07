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

    # Overrides Operation::call, creates the Skill hash and passes it to ::call.
    # module Call
    #   # def __call__(options={}, *dependencies)
    #   def call(options={}, *dependencies)
    #     super( Trailblazer::Operation::Skill(self, options, *dependencies) ) # FIXME: DO this in __call__ as we need the skill hash with self?
    #   end
    # end # Call
  end

  # Returns a `Skill` object that maintains all dependencies for this operation.
  # @returns Trailblazer::Skill
  # def self.Skill(operation, options, *dependencies) # DISCUSS: should this be a private concept?
  #   Trailblazer::Skill.new(
  #     options,
  #     *dependencies,
  #     operation.skills
  #   )
  # end
end
