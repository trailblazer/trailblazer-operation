require "test_helper"

class DeclarativeApiTest < Minitest::Spec
  #---
  #- step, pass, fail

  # Test: step/pass/fail
  # * do they deviate properly?
  class Create < Trailblazer::Operation
    step :decide!
    pass :wasnt_ok!
    pass :was_ok!
    fail :return_true!
    fail :return_false!

    step :bla, input: ->(ctx, *) { {id: ctx.inspect} }, output: ->(scope, ctx) { ctx["hello"] = scope["1"]; ctx }

    def bla(ctx, id:1, **)
      puts id
      true
    end

    def decide!(options, decide: raise, **)
      options["a"] = true
      decide
    end

    def wasnt_ok!(options, **)
      options["y"] = false
    end

    def was_ok!(options, **)
      options["x"] = true
    end

    def return_true!(options, **); options["b"] = true end

    def return_false!(options, **); options["c"] = false end
  end

  it { Create.(decide: true).inspect("a", "x", "y", "b", "c").must_equal %{<Result:true [true, true, false, nil, nil] >} }
  it { Create.(decide: false).inspect("a", "x", "y", "b", "c").must_equal %{<Result:false [true, nil, nil, true, false] >} }
  it { Create.(decide: nil).keys.must_equal(%i(decide a b c)) }
  it { Create.(decide: nil).to_hash.must_equal(decide: nil, a: true, b: true, c: false) }
  #---
  #- trace

  it do
  end

  #---
  #- empty class
  class Noop < Trailblazer::Operation
  end

  it { Noop.().inspect("params").must_equal %{<Result:true [nil] >} }
  it { Noop.().keys.must_equal([]) }
  it { Noop.().to_hash.must_equal({}) }

  #---
  #- pass
  #- fail
  class Update < Trailblazer::Operation
    pass ->(options, **) { options["a"] = false }
    step ->(options, params: raise, **) { options["b"] = params[:decide] }
    fail ->(options, **) { options["c"] = true }
  end

  it { Update.("params" => {decide: true}).inspect("a", "b", "c").must_equal %{<Result:true [false, true, nil] >} }
  it { Update.("params" => {decide: false}).inspect("a", "b", "c").must_equal %{<Result:false [false, false, true] >} }

  #---
  #- inheritance
  class Upsert < Update
    step ->(options, **) { options["d"] = 1 }
  end

  class Unset < Upsert
    step ->(options, **) { options["e"] = 2 }
  end

  class Aliases < Update
    def self.flow_options_for_public_call(*)
      {
        context_options: {
          aliases: { 'b' => :settle },
          container_class: Trailblazer::Context::Container::WithAliases,
        }
      }
    end
  end

  it "allows to inherit" do
    Upsert.("params" => {decide: true}).inspect("a", "b", "c", "d", "e").must_equal %{<Result:true [false, true, nil, 1, nil] >}
    Unset. ("params" => {decide: true}).inspect("a", "b", "c", "d", "e").must_equal %{<Result:true [false, true, nil, 1, 2] >}
  end

# Mixing keywords and string keys in {Operation.call}.
# Test that {.(params: {}, "current_user" => user)} is processed properly
  class Collect < Trailblazer::Operation
    # step ->(ctx, **) { ctx[:keys] }
  end

  it "contains all keys from {call}" do
    result = Collect.(params: {}, "current_user" => Module)
    _(result.inspect).must_equal %{<Result:true #<Trailblazer::Context::Container wrapped_options={:params=>{}, \"current_user\"=>Module} mutable_options={}> >}
  end

  #---
  #- ctx container
  it do
    options = { "params" => {decide: true} }

    # Default call
    result = Update.(options)
    result.inspect("a", "b", "c").must_equal %{<Result:true [false, true, nil] >}

    # Circuit interface call
    signal, (ctx, _) = Update.([Update.options_for_public_call(options), {}], **{})

    signal.inspect.must_equal %{#<Trailblazer::Activity::Railway::End::Success semantic=:success>}
    ctx.inspect.must_equal %{#<Trailblazer::Context::Container wrapped_options={\"params\"=>{:decide=>true}} mutable_options={\"a\"=>false, \"b\"=>true}>}

    # Call by passing aliases as an argument.
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0.0")
      result = Update.(
        options,
        {
          context_options: {
            aliases: { 'b' => :settle },
            container_class: Trailblazer::Context::Container::WithAliases,
          }
        }
      )
    else
      result = Update.call_with_flow_options(
        options,
        {
          context_options: {
            aliases: { 'b' => :settle },
            container_class: Trailblazer::Context::Container::WithAliases,
          }
        },
      )
    end

    result[:settle].must_equal true
    # Set aliases by overriding `flow_options` at the compile time.
    result = Aliases.(options)
    result[:settle].must_equal true
  end
end
