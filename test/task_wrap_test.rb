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

      extension: [
        Trailblazer::Activity::TaskWrap::Merge.new(
          Module.new do
            extend Trailblazer::Activity::Path::Plan()

            task Trailblazer::Operation::Wrap::Inject::ReverseMergeDefaults.new( contract: "MyDefaultContract" ),
              id:     "inject.my_default",
              before: "task_wrap.call_task"
          end
        )
      ]
    )

    def model!(options, **)
      options["options.contract"] = options[:contract]
      true
    end
  end

  # it { Create.__call__("adsf", options={}, {}).inspect("MyMacro.contract", "options.contract").must_equal %{} }

  def inspect_hash(hash, *keys)
    Hash[ keys.collect { |key| [key, hash[key]] } ].inspect
  end

  #-
  # default gets set by Injection.
  it do
    direction, (options, _) = Create.__call__( [{}, {}] )

    inspect_hash(options, "options.contract", :contract, "MyMacro.contract").
      must_equal %{{"options.contract"=>nil, :contract=>"MyDefaultContract", "MyMacro.contract"=>"MyDefaultContract"}}
  end

  # injected from outside, Injection skips.
  it do
    direction, (options, _) = Create.__call__( [ { :contract=>"MyExternalContract" }, {} ] )

    inspect_hash(options, "options.contract", :contract, "MyMacro.contract").
      must_equal %{{"options.contract"=>"MyExternalContract", :contract=>"MyExternalContract", "MyMacro.contract"=>"MyExternalContract"}}
  end

  #- Nested task_wraps should not override the outer.
  AnotherMacro = ->( (options, *args), *) do
    options["AnotherMacro.another_contract"] = options[:another_contract]
    [ Trailblazer::Activity::Right, [options, *args] ]
  end

  class Update < Trailblazer::Operation
    step(
      task: ->( (options, *args), * ) {
          _d, *o = Create.__call__( [ options, *args ] )

          [ Trailblazer::Activity::Right, *o ]
        },
      id: "Create"
    )
    step(
      task:           AnotherMacro,
      id:             "AnotherMacro",
      extension: [
        Trailblazer::Activity::TaskWrap::Merge.new(
          Module.new do
            extend Trailblazer::Activity::Path::Plan()

            task Trailblazer::Operation::Wrap::Inject::ReverseMergeDefaults.new( another_contract: "AnotherDefaultContract" ), id: "inject.my_default",
            before: "task_wrap.call_task"
          end
        )
      ]
    )
  end

  it do
    direction, (options, _) = Update.__call__( [ {}, {} ] )

    inspect_hash(options, "options.contract", :contract, "MyMacro.contract", "AnotherMacro.another_contract").
      must_equal %{{"options.contract"=>nil, :contract=>"MyDefaultContract", "MyMacro.contract"=>"MyDefaultContract", "AnotherMacro.another_contract"=>"AnotherDefaultContract"}}
  end
end
