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
      alteration: ->(wrap_circuit) do
        Trailblazer::Circuit::Activity::Before( wrap_circuit,
          Trailblazer::Circuit::Activity::Wrapped::Call,
          Trailblazer::Operation::Railway::Inject( contract: "MyDefaultContract" ),
          direction: Trailblazer::Circuit::Right
        )
      end
    ]

    def model!(options, **)
      options["a.contract"] = options[:contract]
      true
    end
  end

  # it { Create.__call__("adsf", options={}, {}).inspect("MyMacro.contract", "a.contract").must_equal %{} }
  it { Create.__call__("adsf", options={}, {})[1].inspect.must_equal %{{\"a.contract\"=>nil, :contract=>\"MyDefaultContract\", \"MyMacro.contract\"=>\"MyDefaultContract\"}} }
  it { Create.__call__("adsf", options={ :contract=>"MyExternalContract" }, {})[1].inspect.must_equal %{{:contract=>\"MyExternalContract\", \"a.contract\"=>\"MyExternalContract\", \"MyMacro.contract\"=>\"MyExternalContract\"}} }
end
