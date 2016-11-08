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

  # without any options or []
  class New < Trailblazer::Operation
    self.| Validate
  end

  it { New["pipetree"].inspect.must_equal %{[>validate,>>operation.new]} }

  # with options
  class Update < Trailblazer::Operation
    self.| Validate, after: "operation.new"
  end

  it { Update["pipetree"].inspect.must_equal %{[>>operation.new,>validate]} }

  # with :symbol
  class Delete < Trailblazer::Operation
    self.| :call!

    def call!(options)
      self["x"] = options["params"]
    end
  end

  it { Delete.("yo")["x"].must_equal "yo" }

  # proc arguments
  class Forward < Trailblazer::Operation
    self.| ->(input, options) { puts "@@@@@ #{input.inspect}"; puts "@@@@@ #{options.inspect}" }
  end

  it { skip; Forward.({ id: 1 }) }

  #---
  # ::>, ::<, ::>>, :&
  # with proc, method, callable.
  class Right < Trailblazer::Operation
    self.> ->(input, options) { options[">"] = options["params"][:id] }

    self.> :method_name!
    def method_name!(options); self["method_name!"] = options["params"][:id] end

    class MyCallable
      include Uber::Callable
      def call(operation, options); operation["callable"] = options["params"][:id] end
    end
    self.> MyCallable.new
  end

  it { Right.( id: 1 ).slice(">", "method_name!", "callable").must_equal [1, 1, 1] }

  #---
  # inheritance
  class Righter < Right
    self.> ->(input, options) { options["righter"] = true }
  end

  it { Righter.( id: 1 ).slice(">", "method_name!", "callable", "righter").must_equal [1, 1, 1, true] }
end


# args: operation, skills
