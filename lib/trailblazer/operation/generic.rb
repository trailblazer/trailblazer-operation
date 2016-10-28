module Trailblazer
  # Generic initializer for the operation.
  module Operation::Generic
    def initialize(skills={})
      @skills = skills
      self["valid"]  = true # not sure if this flag will survive the power of result/waterfall/matcher objects.
    end

    def call(params)
      process(params)
      self
    end

    # dependency injection interface
    extend Uber::Delegates
    delegates :@skills, :[], :[]=

  private
    def process(*)
    end
  end
end
