require "test_helper"

class ClassDependenciesTest < Minitest::Spec

  #- Operation[] and Operation[]=

  class Index < Trailblazer::Operation
    extend ClassDependencies

    self["model.class"] = Module

    step ->(options, **) { options["a"] = options["model.class"] }
  end

  it { Index.({}).inspect("a", "model.class").must_equal %{<Result:true [Module, Module] >} }
end
