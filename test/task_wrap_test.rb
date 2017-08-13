require "test_helper"

class TaskWrapTest < Minitest::Spec
  MyMacro = ->(direction, options, flow_options) do
    options["MyMacro.contract"] = options[:contract]
    [ direction, options, flow_options ]
  end

  class Create < Trailblazer::Operation
    step :model!
    # step [ MyMacro, { name: "MyMacro" }, { dependencies: { "contract" => :external_maybe } }]
    step [
      MyMacro,
      { name: "MyMacro" },

      { # runner_options:
        alteration: [
          [ :insert_before!, "task_wrap.call_task",
            node: [ Trailblazer::Operation::TaskWrap::Injection::ReverseMergeDefaults( contract: "MyDefaultContract" ), id: "inject.reverse_merge_defaults.{:contract=>MyDefaultContract}" ],
            incoming: Proc.new{ true },
            outgoing: [ Trailblazer::Circuit::Right, {} ]
          ],
        ]
      }

    ]

    def model!(options, **)
      options["options.contract"] = options[:contract]
      true
    end
  end

  # it { Create.__call__("adsf", options={}, {}).inspect("MyMacro.contract", "options.contract").must_equal %{} }

  #-
  # default gets set by Injection.
  it do
    direction, options, _ = Create.__call__( Create.instance_variable_get(:@start), {}, {} )

    Trailblazer::Hash.inspect(options, "options.contract", :contract, "MyMacro.contract").
      must_equal %{{"options.contract"=>nil, :contract=>"MyDefaultContract", "MyMacro.contract"=>"MyDefaultContract"}}
  end

  # injected from outside, Injection skips.
  it do
    direction, options, _ = Create.__call__( Create.instance_variable_get(:@start), { :contract=>"MyExternalContract" }, {} )

    Trailblazer::Hash.inspect(options, "options.contract", :contract, "MyMacro.contract").
      must_equal %{{"options.contract"=>"MyExternalContract", :contract=>"MyExternalContract", "MyMacro.contract"=>"MyExternalContract"}}
  end

  #- Nested task_wraps should not override the outer.
  AnotherMacro = ->(direction, options, flow_options) do
    options["AnotherMacro.another_contract"] = options[:another_contract]
    [ direction, options, flow_options ]
  end

  class Update < Trailblazer::Operation
    step [
      ->(direction, options, flow_options) { _d, _o, _f = Create.__call__(Create.instance_variable_get(:@start), options, flow_options); [ Trailblazer::Circuit::Right, _o, _f ] },
      { name: "Create" }
    ]
    step [
      AnotherMacro,
      { name: "AnotherMacro" },

      { # runner_options:
        alteration: [
          [ :insert_before!, "task_wrap.call_task",
            node: [ Trailblazer::Operation::TaskWrap::Injection::ReverseMergeDefaults( another_contract: "AnotherDefaultContract" ), id: "inject.reverse_merge_defaults.{:another_contract=>AnotherDefaultContract}" ],
            incoming: Proc.new{ true },
            outgoing: [ Trailblazer::Circuit::Right, {} ]
          ],
        ]
      }

    ]
  end

  it do
    direction, options, _ = Update.__call__( Update.instance_variable_get(:@start), {}, {} )

    Trailblazer::Hash.inspect(options, "options.contract", :contract, "MyMacro.contract", "AnotherMacro.another_contract").
      must_equal %{{"options.contract"=>nil, :contract=>"MyDefaultContract", "MyMacro.contract"=>"MyDefaultContract", "AnotherMacro.another_contract"=>"AnotherDefaultContract"}}
  end
end
