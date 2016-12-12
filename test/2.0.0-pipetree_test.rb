require "test_helper"

class Ruby200PipetreeTest < Minitest::Spec
  class Create < Trailblazer::Operation
    consider ->(*, params:, **) { params["run"] }    # only test kws.
    step     ->(options, params:nil, **) { options["x"] = params["run"] } # read and write.
    step     ->(options) { options["y"] = options["params"]["run"] } # old API.
  end

  it { Create.("run" => false).inspect("x", "y").must_equal %{<Result:false [nil, nil] >} }
  it { Create.("run" => true).inspect("x", "y").must_equal %{<Result:true [true, true] >} }

  #- instance methods
  class Update < Trailblazer::Operation
    consider :params!    # only test kws.
    step     :x! # read and write.
    step     :y! # old API.

    def params!(*, params:, **)
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
      def self.call(*, params:, **)
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

    consider Params
    step     X
    step     Y
  end

  it { Delete.("run" => false).inspect("x", "y").must_equal %{<Result:false [nil, nil] >} }
  it { Delete.("run" => true).inspect("x", "y").must_equal %{<Result:true [true, true] >} }
end
