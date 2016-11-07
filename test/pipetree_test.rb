require "test_helper"

class PipetreeTest < Minitest::Spec
  module Validate
    extend Trailblazer::Operation::Stepable

    def self.import!(operation, pipe)
      pipe.(:>, ->{ snippet }, name: "validate", before: "operation.new")
    end
  end
  #---
  # ::|
  # without options
  class Create < Trailblazer::Operation
    self.| Validate[]
  end

  it { Create["pipetree"].inspect.must_equal %{[>validate,>>operation.new]} }

  # with options
  class Update < Trailblazer::Operation
    self.| Validate[], after: "operation.new"
  end

  it { Update["pipetree"].inspect.must_equal %{[>>operation.new,>validate]} }
end
