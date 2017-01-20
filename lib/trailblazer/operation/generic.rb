module Trailblazer
  # Generic initializer for the operation.
  module Operation::Generic
    def initialize(skills={})
      @skills = skills
    end

    # dependency interface
    extend Forwardable
    def_delegators :@skills, :[], :[]=
  end
end
