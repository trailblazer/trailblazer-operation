require "test_helper"

class ClassDependenciesTest < Minitest::Spec
  #- Operation[] and Operation[]=

  class Index < Trailblazer::Operation
    extend ClassDependencies

    self["model.class"] = Module

    step ->(options, **) { options["a"] = options["model.class"] }
  end

  it { Index.({}).inspect("a", "model.class").must_equal %{<Result:true [Module, Module] >} }
  it "creates separate ctx for circuit interface" do
    signal, (ctx, _) = Index.([{}, {}], {})

    ctx["model.class"].inspect.must_equal %{Module} # FIXME: should this be here?
    ctx[:a].inspect.must_equal %{Module}
  end
end
