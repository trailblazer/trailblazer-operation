require "test_helper"

require "trailblazer/operation/inject" # an optional feature.com.

class TaskWrapTest < Minitest::Spec
  MyMacro = ->( (options, *args), *) do
    options["MyMacro.contract"] = options[:contract]
    [ Trailblazer::Activity::Right, [options, *args] ]
  end

  class Create < Trailblazer::Operation
    step :model!
    # step [ MyMacro, { name: "MyMacro" }, { dependencies: { "contract" => :external_maybe } }]
    step(
      task: MyMacro,
      id: "MyMacro",

      Trailblazer::Activity::DSL::Extension.new(
        Trailblazer::Activity::TaskWrap::Merge.new(
          Module.new do
            extend Trailblazer::Activity::Path::Plan()

            task Trailblazer::Operation::Wrap::Inject::ReverseMergeDefaults.new( contract: "MyDefaultContract" ),
              id:     "inject.my_default",
              before: "task_wrap.call_task"
          end
        )
      ) => true
    )

    def model!(options, **)
      options["options.contract"] = options[:contract]
      true
    end
  end

  # it { Create.call("adsf", options={}, {}).inspect("MyMacro.contract", "options.contract").must_equal %{} }

  def inspect_hash(hash, *keys)
    Hash[ keys.collect { |key| [key, hash[key]] } ].inspect
  end

  #-
  # default gets set by Injection.
  it do
    result = Create.call( {} )

    inspect_hash(result, "options.contract", :contract, "MyMacro.contract").
      must_equal %{{"options.contract"=>nil, :contract=>"MyDefaultContract", "MyMacro.contract"=>"MyDefaultContract"}}
  end

  # injected from outside, Injection skips.
  it do
    result = Create.call( { :contract=>"MyExternalContract" } )

    inspect_hash(result, "options.contract", :contract, "MyMacro.contract").
      must_equal %{{"options.contract"=>"MyExternalContract", :contract=>"MyExternalContract", "MyMacro.contract"=>"MyExternalContract"}}
  end

  #- Nested task_wraps should not override the outer.
  AnotherMacro = ->( (options, *args), *) do
    options["AnotherMacro.another_contract"] = options[:another_contract]
    [ Trailblazer::Activity::Right, [options, *args] ]
  end

  class Update < Trailblazer::Operation
    step(
      task: ->( (options, *args), circuit_options ) {
          _d, *o = Create.call( [ options, *args ], circuit_options )

          [ Trailblazer::Activity::Right, *o ]
        },
      id: "Create"
    )
    step(
      task:           AnotherMacro,
      id:             "AnotherMacro",
      Trailblazer::Activity::DSL::Extension.new(
        Trailblazer::Activity::TaskWrap::Merge.new(
          Module.new do
            extend Trailblazer::Activity::Path::Plan()

            task Trailblazer::Operation::Wrap::Inject::ReverseMergeDefaults.new( another_contract: "AnotherDefaultContract" ), id: "inject.my_default",
            before: "task_wrap.call_task"
          end
        )
      ) => true,
    )
  end

  it do
    result = Update.call( {} )

    inspect_hash(result, "options.contract", :contract, "MyMacro.contract", "AnotherMacro.another_contract").
      must_equal %{{"options.contract"=>nil, :contract=>"MyDefaultContract", "MyMacro.contract"=>"MyDefaultContract", "AnotherMacro.another_contract"=>"AnotherDefaultContract"}}
  end
end
