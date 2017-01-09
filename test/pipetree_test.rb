require "test_helper"

class PipetreeTest < Minitest::Spec
  module Validate
    def self.import!(operation, pipe)
      pipe.(:>, ->{ snippet }, name: "validate", before: "operation.new")
    end
  end

  #---
  # ::|
  # without options
  class Create < Trailblazer::Operation
    step [Validate]
  end

  it { Create["pipetree"].inspect.must_equal %{[>validate,>>operation.new]} }

  # without any options or []
  # class New < Trailblazer::Operation
  #   step Validate
  # end

  # it { New["pipetree"].inspect.must_equal %{[>validate,>>operation.new]} }

  # with options
  class Update < Trailblazer::Operation
    step [Validate], after: "operation.new"
  end

  it { Update["pipetree"].inspect.must_equal %{[>>operation.new,>validate]} }

  #---
  # ::step

  #-
  #- with :symbol
  class Delete < Trailblazer::Operation
    step :call!

    def call!(options)
      self["x"] = options["params"]
    end
  end

  it { Delete.("yo")["x"].must_equal "yo" }

  #- inheritance
  class Remove < Delete
  end

  it { Remove.("yo")["x"].must_equal "yo" }

  # proc arguments
  class Forward < Trailblazer::Operation
    step ->(input, options) { puts "@@@@@ #{input.inspect}"; puts "@@@@@ #{options.inspect}" }
  end

  it { skip; Forward.({ id: 1 }) }

  #---
  # ::>, ::<, ::>>, :&
  # with proc, method, callable.
  class Right < Trailblazer::Operation
    MyProc = ->(*) { }
    success ->(options) { options[">"] = options["params"][:id] }, better_api: true

    success :method_name!
    def method_name!(options); self["method_name!"] = options["params"][:id] end

    class MyCallable
      include Uber::Callable
      def call(options); options["callable"] = options["params"][:id] end
    end
    success MyCallable.new
  end

  it { Right.( id: 1 ).slice(">", "method_name!", "callable").must_equal [1, 1, 1] }
  it { Right["pipetree"].inspect.must_equal %{[>>operation.new,>PipetreeTest::Right:66,>method_name!,>PipetreeTest::Right::MyCallable]} }

  #---
  # inheritance
  class Righter < Right
    success ->(options) { options["righter"] = true }
  end

  it { Righter.( id: 1 ).slice(">", "method_name!", "callable", "righter").must_equal [1, 1, 1, true] }
end
