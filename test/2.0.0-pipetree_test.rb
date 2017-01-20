require "test_helper"

class KWBugsTest < Minitest::Spec
  Merchant = Struct.new(:id)

  class Merchant::New < Trailblazer::Operation
    step ->(options) {
      options["model"] = 1
       options["bla"] = true # this breaks Ruby 2.2.2.
     }

    step :add!
    def add!(yo:nil, model:nil, **)
      raise if model.nil?
    end
  end

  it { Merchant::New.( {}, { "yo"=> nil   } ) }
end

class KWOptionsTest < Minitest::Spec
  X = Trailblazer::Operation::Option::KW.( ->(options, **) { options["x"] = true } )
  Y = Trailblazer::Operation::Option::KW.( ->(options, params:nil, **) { options["y"] = params } )
  Z = Trailblazer::Operation::Option::KW.( ->(options, params:nil, z:nil, **) { options["kw_z"] = z } )
  A = Trailblazer::Operation::Option::KW.( ->(options, params:nil, z:nil, **) { options["options_z"] = options["z"] } )

  class Create < Trailblazer::Operation
    step [ ->(input, options) { X.(input, options, z: "Z!") }, name: "X" ]
    step [ ->(input, options) { Y.(input, options, z: "Z!") }, name: "Y" ]
    step [ ->(input, options) { Z.(input, options, z: "Z!") }, name: "Z" ]
    step [ ->(input, options) { A.(input, options, z: "Z!") }, name: "A" ]
  end

  it { Create.({ params: "yo" }, "z" => 1).inspect("x", "y", "kw_z", "options_z").must_equal %{<Result:true [true, {:params=>\"yo\"}, "Z!", 1] >} }
end


class Ruby200PipetreeTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step ->(*, params:nil, **) { params["run"] }    # only test kws.
    step ->(options, params:nil, **) { options["x"] = params["run"] } # read and write.
    step ->(options) { options["y"] = options["params"]["run"] } # old API.
  end

  it { Create.("run" => false).inspect("x", "y").must_equal %{<Result:false [nil, nil] >} }
  it { Create.("run" => true).inspect("x", "y").must_equal %{<Result:true [true, true] >} }

  #- instance methods
  class Update < Trailblazer::Operation
    step :params!    # only test kws.
    step :x! # read and write.
    step :y! # old API.

    def params!(*, params:nil, **)
      params["run"]
    end

    def x!(options, params:nil, **)
      options["x"] = params["run"]
    end

    def y!(options)
      options["y"] = options["params"]["run"]
    end
  end

  it { Update.("run" => false).inspect("x", "y").must_equal %{<Result:false [nil, nil] >} }
  it { Update.("run" => true).inspect("x", "y").must_equal %{<Result:true [true, true] >} }


  class Delete < Trailblazer::Operation
    class Params
      extend Uber::Callable
      def self.call(*, params:nil, **)
        params["run"]
      end
    end

    class X
      extend Uber::Callable
      def self.call(options, params:nil, **)
        options["x"] = params["run"]
      end
    end

    class Y
      extend Uber::Callable
      def self.call(options)
        options["y"] = options["params"]["run"]
      end
    end

    step Params
    step X
    step Y
  end

  it { Delete.("run" => false).inspect("x", "y").must_equal %{<Result:false [nil, nil] >} }
  it { Delete.("run" => true).inspect("x", "y").must_equal %{<Result:true [true, true] >} }
end
