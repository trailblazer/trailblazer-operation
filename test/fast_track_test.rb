require "test_helper"

class FastTrackTest < Minitest::Spec
  # #failure fails fast.
  # class Create < Trailblazer::Operation
  #   step ->(options, *) { options["x"] = options["dont_fail"] }
  #   failure ->(options, *) { options["a"] = true; options["fail_fast"] }, fail_fast: true
  #   failure ->(options, *) { options["b"] = true }
  #   step ->(options, *) { options["y"] = true }
  # end

  # puts Create["pipetree"].inspect

  # require "trailblazer/diagram/bpmn"
  # puts Trailblazer::Diagram::BPMN.to_xml(Create["pipetree"])

  # it { Create.({}, "fail_fast" => true, "dont_fail" => true ).inspect("x", "a", "b", "y").must_equal %{<Result:true [true, nil, nil, true] >} }
  # it { Create.({}, "fail_fast" => true                  ).inspect("x", "a", "b", "y").must_equal %{<Result:false [nil, true, nil, nil] >} }
  # it { Create.({}, "fail_fast" => false                 ).inspect("x", "a", "b", "y").must_equal %{<Result:false [nil, true, nil, nil] >} }

  # #success passes fast.
  class Retrieve < Trailblazer::Operation
    pass ->(options, **) { options["x"] = options["dont_fail"] }, pass_fast: true
    fail ->(options, **) { options["b"] = true }
    step ->(options, **) { options["y"] = true }
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
    fail ->(options, *) { options["b"] = true }
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

  # without proper configuration, emitting a FastTrack signal is illegal.
  it { assert_raises(Trailblazer::Circuit::IllegalOutputSignalError) { Create.().inspect("x", "y", "a").must_equal %{<Result:false [true, nil, nil] >} } }

  class Update < Trailblazer::Operation
    step ->(options, *) { options["x"] = true; Railway.fail_fast! }, fast_track: true
    step ->(options, *) { options["y"] = true }
    failure ->(options, *) { options["a"] = true }
  end

  it { Update.().inspect("x", "y", "a").must_equal %{<Result:false [true, nil, nil] >} }
end

class PassFastBangTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(options, *) { options["x"] = true; Railway.pass_fast! }, fast_track: true
    step ->(options, *) { options["y"] = true }
    failure ->(options, *) { options["a"] = true }
  end

  it { Create.().inspect("x", "y", "a").must_equal %{<Result:true [true, nil, nil] >} }
end

#-
class NestedFastTrackTest < Minitest::Spec
  #- The ::step DSL method automatically connects the nested's End.fail_fast/End.pass_fast to Update's End.fail_fast/End.pass_fast.
  class Edit < Trailblazer::Operation
    step :a, fast_track: true # task is connected to End.pass_fast and End.fail_fast.

    def a(options, edit_return:, **)
      options["a"] = 1
      edit_return # End.success, End.pass_fast, etc.
    end
  end

  class Update < Trailblazer::Operation
    step Trailblazer::Activity::Subprocess( Edit, call: :__call__ ), node_data: { id: "Subprocess/" }, outputs: Edit.outputs, fast_track: true
    step :b
    fail :f

    def b(options, a:, **)
      options["b"] = a+1
    end

    def f(options, **)
      options["f"] = 3
    end
  end

  # Edit returns End.success
  it { Update.({}, edit_return: true).inspect("a", "b", "f").must_equal %{<Result:true [1, 2, nil] >} }
  # Edit returns End.failure
  it { Update.({}, edit_return: false).inspect("a", "b", "f").must_equal %{<Result:false [1, nil, 3] >} }

  # Edit returns End.pass_fast
  it { Update.({}, edit_return: Trailblazer::Operation::Railway.pass_fast!).inspect("a", "b", "f").must_equal %{<Result:true [1, nil, nil] >} }

  # Edit returns End.fail_fast
  it { Update.({}, edit_return: Trailblazer::Operation::Railway.fail_fast!).inspect("a", "b", "f").must_equal %{<Result:false [1, nil, nil] >} }

  # it do
  #   require "trailblazer/developer"
  #   puts Trailblazer::Developer::Client.push( operation: Update, name: "Update/#{Time.now}" )

  # end
end

