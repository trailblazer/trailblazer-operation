require "test_helper"

class PipetreeTest < Minitest::Spec
  def self.Validate
    step = ->{ snippet }

    [ step, name: "validate", before: "operation.new" ]
  end

  # without options
  class Create < Trailblazer::Operation
    step PipetreeTest::Validate()
    step PipetreeTest::Validate(), name: "VALIDATE!"
  end

  it { Create["pipetree"].inspect.must_equal %{[>validate,>VALIDATE!,>operation.new]} }



  # with options
  class Update < Trailblazer::Operation
    step PipetreeTest::Validate(), after: "operation.new"
  end

  it { Update["pipetree"].inspect.must_equal %{[>operation.new,>validate]} }

  #---
  # ::step

  #-
  #- with :symbol
  class Delete < Trailblazer::Operation
    step :call!

    def call!(options)
      # self["x"] = options["params"]
      options["x"] = options["params"]
    end
  end

  it { Delete.("yo")["x"].must_equal "yo" }

  #- inheritance
  class Remove < Delete
  end

  it { Remove.("yo")["x"].must_equal "yo" }


  #---
  # inheritance
  class Righter < Right
    success ->(options) { options["righter"] = true }
  end

  it { Righter.( id: 1 ).slice(">", "method_name!", "callable", "righter").must_equal [1, 1, 1, true] }
end


class FailPassFastOptionTest < Minitest::Spec
  # #failure fails fast.
  class Create < Trailblazer::Operation
    step ->(options, *) { options["x"] = options["dont_fail"] }
    failure ->(options, *) { options["a"] = true; options["fail_fast"] }, fail_fast: true
    failure ->(options, *) { options["b"] = true }
    step ->(options, *) { options["y"] = true }
  end

  it { Create.({}, "fail_fast" => true, "dont_fail" => true ).inspect("x", "a", "b", "y").must_equal %{<Result:true [true, nil, nil, true] >} }
  it { Create.({}, "fail_fast" => true                  ).inspect("x", "a", "b", "y").must_equal %{<Result:false [nil, true, nil, nil] >} }
  it { Create.({}, "fail_fast" => false                 ).inspect("x", "a", "b", "y").must_equal %{<Result:false [nil, true, nil, nil] >} }

  # #success passes fast.
  class Retrieve < Trailblazer::Operation
    success ->(options, *) { options["x"] = options["dont_fail"] }, pass_fast: true
    failure ->(options, *) { options["b"] = true }
    step ->(options, *) { options["y"] = true }
  end

  it { Retrieve.({}, "dont_fail" => true  ).inspect("x", "b", "y").must_equal %{<Result:true [true, nil, nil] >} }
  it { Retrieve.({}, "dont_fail" => false ).inspect("x", "b", "y").must_equal %{<Result:true [false, nil, nil] >} }

  # #step fails fast if option set and returns false.
  class Update < Trailblazer::Operation
    step ->(options, *) { options["x"] = true }
    step ->(options, *) { options["a"] = options["dont_fail"] }, fail_fast: true # only on false.
    failure ->(options, *) { options["b"] = true }
    step ->(options, *) { options["y"] = true }
  end

  it { Update.({}, "dont_fail" => true).inspect("x", "a", "b", "y").must_equal %{<Result:true [true, true, nil, true] >} }
  it { Update.({}                     ).inspect("x", "a", "b", "y").must_equal %{<Result:false [true, nil, nil, nil] >} }

  # #step passes fast if option set and returns true.
  class Delete < Trailblazer::Operation
    step ->(options, *) { options["x"] = true }
    step ->(options, *) { options["a"] = options["dont_fail"] }, pass_fast: true # only on true.
    failure ->(options, *) { options["b"] = true }
    step ->(options, *) { options["y"] = true }
  end

  it { Delete.({}, "dont_fail" => true).inspect("x", "a", "b", "y").must_equal %{<Result:true [true, true, nil, nil] >} }
  it { Delete.({}                     ).inspect("x", "a", "b", "y").must_equal %{<Result:false [true, nil, true, nil] >} }
end

class FailBangTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(options, *) { options["x"] = true; Railway.fail! }
    step ->(options, *) { options["y"] = true }
    failure ->(options, *) { options["a"] = true }
  end

  it { Create.().inspect("x", "y", "a").must_equal %{<Result:false [true, nil, true] >} }
end

class PassBangTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(options, *) { options["x"] = true; Railway.pass! }
    step ->(options, *) { options["y"] = true }
    failure ->(options, *) { options["a"] = true }
  end

  it { Create.().inspect("x", "y", "a").must_equal %{<Result:true [true, true, nil] >} }
end

class FailFastBangTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(options, *) { options["x"] = true; Railway.fail_fast! }
    step ->(options, *) { options["y"] = true }
    failure ->(options, *) { options["a"] = true }
  end

  it { Create.().inspect("x", "y", "a").must_equal %{<Result:false [true, nil, nil] >} }
end

class PassFastBangTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(options, *) { options["x"] = true; Railway.pass_fast! }
    step ->(options, *) { options["y"] = true }
    failure ->(options, *) { options["a"] = true }
  end

  it { Create.().inspect("x", "y", "a").must_equal %{<Result:true [true, nil, nil] >} }
end


class OverrideTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step :a
    step :b
  end

  class Update < Create
    step :a, override: true
  end

# FIXME: also test Macro
  it { Create["pipetree"].inspect.must_equal %{[>operation.new,>a,>b]} }
  it { Update["pipetree"].inspect.must_equal %{[>operation.new,>a,>b]} }
end
