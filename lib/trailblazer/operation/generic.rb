module Trailblazer
  # Generic initializer for the operation.
  module Operation::Generic
    def initialize(skills={})
      @skills = skills
    end

    # dependency injection interface
    extend Uber::Delegates
    delegates :@skills, :[], :[]=
  end
end
