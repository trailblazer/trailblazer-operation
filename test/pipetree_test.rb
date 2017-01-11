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

  it { Create["pipetree"].inspect.must_equal %{[>validate,operation.new]} }

  # without any options or []
  # class New < Trailblazer::Operation
  #   step Validate
  # end

  # it { New["pipetree"].inspect.must_equal %{[>validate,>>operation.new]} }

  # with options
  class Update < Trailblazer::Operation
    step [Validate], after: "operation.new"
  end

  it { Update["pipetree"].inspect.must_equal %{[operation.new,>validate]} }

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
  it { Right["pipetree"].inspect.must_equal %{[operation.new,pipetree_test.rb:66,method_name!,PipetreeTest::Right::MyCallable]} }

  #---
  # inheritance
  class Righter < Right
    success ->(options) { options["righter"] = true }
  end

  it { Righter.( id: 1 ).slice(">", "method_name!", "callable", "righter").must_equal [1, 1, 1, true] }
end


class FailFastTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(options, *) { options["x"] = options["dont_fail"] }
    failure ->(options, *) { options["a"] = true; options["fail_fast"] }, fail_fast: true
    failure ->(options, *) { options["b"] = true }
    step ->(options, *) { options["y"] = true }
  end

  it { Create.({}, "fail_fast" => true, "dont_fail" => true ).inspect("x", "a", "b", "y").must_equal %{<Result:true [true, nil, nil, true] >} }
  it { Create.({}, "fail_fast" => true                  ).inspect("x", "a", "b", "y").must_equal %{<Result:false [nil, true, nil, nil] >} }
  it { Create.({}, "fail_fast" => false                 ).inspect("x", "a", "b", "y").must_equal %{<Result:false [nil, true, nil, nil] >} }

  class Update < Trailblazer::Operation
    step ->(options, *) { options["x"] = true }
    step ->(options, *) { options["a"] = true }, fail_fast: true
    failure ->(options, *) { options["b"] = true }
    step ->(options, *) { options["y"] = true }
  end

  it { Update.({}).inspect("x", "a", "b", "y").must_equal %{<Result:false [true, true, nil, nil] >} }
end

class FailBangTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(options, *) { options["x"] = true; Step.fail! }
    step ->(options, *) { options["y"] = true }
    failure ->(options, *) { options["a"] = true }
  end

  it { Create.().inspect("x", "y", "a").must_equal %{<Result:false [true, nil, true] >} }

  class Update < Trailblazer::Operation
    success ->(options, *) { options["x"] = true; Step.fail! }
    success ->(options, *) { options["y"] = true }
    failure ->(options, *) { options["a"] = true }
  end

  it { Update.().inspect("x", "y", "a").must_equal %{<Result:false [true, nil, true] >} }
end

class FailFastBangTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(options, *) { options["x"] = true; Step.fail_fast! }
    step ->(options, *) { options["y"] = true }
    failure ->(options, *) { options["a"] = true }
  end

  it { Create.().inspect("x", "y", "a").must_equal %{<Result:false [true, nil, nil] >} }

  class Update < Trailblazer::Operation
    step ->(options, *) { options["y"] = true; false }
    failure ->(options, *) { options["x"] = true; Step.fail_fast! }
    failure ->(options, *) { options["a"] = true }
  end

  it { Update.().inspect("y", "x", "a").must_equal %{<Result:false [true, true, nil] >} }
end
