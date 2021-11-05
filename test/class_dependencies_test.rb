require "test_helper"

class ClassDependenciesTest < Minitest::Spec
  #- Operation[] and Operation[]=

  class Index < Trailblazer::Operation
    extend ClassDependencies

    self["model.class"] = Module

    step ->(ctx, **) { ctx["a"] = ctx["model.class"] }
  end

  it { Index.({}).inspect("a", "model.class").must_equal %{<Result:true [Module, Module] >} }

  it "creates separate ctx for circuit interface" do

    raise "this can't work since the OP is run without TaskWrap.invoke"
    signal, (ctx, _) = Index.([{}, {}], {})

    ctx[:a].inspect.must_equal %{Module}
    ctx["model.class"].inspect.must_equal %{Module} # FIXME: should this be here?
  end

# nested OPs
  it "injects class dependencies for nested OP" do
    class Home < Trailblazer::Operation
      step Subprocess(Index)
    end

    # "model.class" gets injected automatically just before {Index}.
    Home.({params: {}}).inspect.must_equal %{<Result:true #<Trailblazer::Context::Container wrapped_options={:params=>{}, \"model.class\"=>Module} mutable_options={\"a\"=>Module}> >}

    # "model.class" gets injected by user and overrides class dependencies.
    Home.({params: {}, "model.class" => Symbol}).inspect.must_equal %{<Result:true #<Trailblazer::Context::Container wrapped_options={:params=>{}, :\"model.class\"=>Symbol, \"model.class\"=>Symbol} mutable_options={\"a\"=>Symbol}> >}


    class Dashboard < Trailblazer::Operation
      extend ClassDependencies
      self["model.class"] = Float # this overrides {Index}'es dependency

      pass ->(ctx, **) { ctx[:Dashboard] = ctx["model.class"] }
      step Subprocess(Index)
    end

  # "model.class" gets injected automatically in {Dashboard} and overrides the {Index} input.
    Dashboard.({params: {}}).inspect.must_equal %{<Result:true #<Trailblazer::Context::Container wrapped_options={:params=>{}, \"model.class\"=>Float} mutable_options={\"a\"=>Module}> >}

  end

  describe "inheritance" do
    it "reader/setter read from separate config" do
      subclass = Class.new(Index)

      subclass["model.class"].must_equal Module
      subclass["model.class"] = Class
      subclass["model.class"].must_equal Class
      Index["model.class"].must_equal Module
    end

  end
end
