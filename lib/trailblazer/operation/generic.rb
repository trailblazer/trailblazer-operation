module Trailblazer
  # Generic initializer for the operation.
  module Operation::Generic
    def initialize(skills={})
      @skills = skills
    end

    def call(params)
      process(params)
      self
    end
    # Alternatively, you could use your own Call module ->(input, options) { input.call(options["params"]) }
    # and either use >Call (result doesn't matter) or >>Call (result matters).

    # dependency injection interface
    extend Uber::Delegates
    delegates :@skills, :[], :[]=

  private
    def process(*)
    end
  end
end
