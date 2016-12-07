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
    self.| [Validate]
  end

  it { Create["pipetree"].inspect.must_equal %{[>validate,>>operation.new]} }

  # without any options or []
  # class New < Trailblazer::Operation
  #   self.| Validate
  # end

  # it { New["pipetree"].inspect.must_equal %{[>validate,>>operation.new]} }

  # with options
  class Update < Trailblazer::Operation
    self.| [Validate], after: "operation.new"
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
    MyProc = ->(*) { }
    self.> ->(options) { options[">"] = options["params"][:id] }, better_api: true

    self.> :method_name!
    def method_name!(options); self["method_name!"] = options["params"][:id] end

    class MyCallable
      include Uber::Callable
      def call(options); options["callable"] = options["params"][:id] end
    end
    self.> MyCallable.new
  end

  it { Right.( id: 1 ).slice(">", "method_name!", "callable").must_equal [1, 1, 1] }
  it { Right["pipetree"].inspect.must_equal %{[>>operation.new,>PipetreeTest::Right:56,>method_name!,>PipetreeTest::Right::MyCallable]} }

  #---
  # inheritance
  class Righter < Right
    self.> ->(options) { options["righter"] = true }
  end

  it { Righter.( id: 1 ).slice(">", "method_name!", "callable", "righter").must_equal [1, 1, 1, true] }
end

#---
#- kw args
class OperationKwArgsTest < Minitest::Spec
  Song = Struct.new(:id)

  class Create < Trailblazer::Operation
    self.> ->(options) { options["model"] = "Object" }
    # self.> ->(model:) { snippet }
  end

  it {
    skip
    Create.() }
end
