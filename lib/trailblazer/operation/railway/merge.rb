module Trailblazer::Operation::Railway
  module Merge
    # Marks a hash so it gets merged onto rather than overriding the previously
    # existing options.
    def Merge(*args, &block)
      ::Declarative::Variables::Merge(*args, &block)
    end
  end
end
