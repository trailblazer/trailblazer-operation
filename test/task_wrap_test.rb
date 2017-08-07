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
        alteration: ->(wrap_circuit) do
          Trailblazer::Circuit::Activity::Before( wrap_circuit,
            Trailblazer::Circuit::Wrap::Call,
            Trailblazer::Operation::TaskWrap::Injection::ReverseMergeDefaults( contract: "MyDefaultContract" ),
            direction: Trailblazer::Circuit::Right
          )
        end,
      }

    ]

    def model!(options, **)
      options["options.contract"] = options[:contract]
      true
    end
  end

  # it { Create.__call__("adsf", options={}, {}).inspect("MyMacro.contract", "options.contract").must_equal %{} }
  it do
    direction, options, _ = Create.__call__( Create.instance_variable_get(:@start), {}, {} )

    Trailblazer::Hash.inspect(options, "options.contract", :contract, "MyMacro.contract").
      must_equal %{{"options.contract"=>nil, :contract=>"MyDefaultContract", "MyMacro.contract"=>"MyDefaultContract"}}
  end
  # injected from outside
  it do
    direction, options, _ = Create.__call__( "adsf", { :contract=>"MyExternalContract" }, {} )
    Trailblazer::Hash.inspect(options, "options.contract", :contract, "MyMacro.contract").
      must_equal %{{"options.contract"=>"MyExternalContract", :contract=>"MyExternalContract", "MyMacro.contract"=>"MyExternalContract"}}
  end
end
