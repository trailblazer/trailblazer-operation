require "test_helper"

# Tests
# ---  step ->(*) { snippet }
# ---  step Callable
# ---  step :method
# ---  step MyMacro
class StepTest < Minitest::Spec
  class Callable
    def self.call(options, b:nil, **)
      options["b"] = b
    end
  end

  module Implementation
    module_function
    def c(options, c:nil, **)
      options["c"] = c
    end
  end

  MyMacro = ->(options, e:nil, **) { options["e"] = e }

  class Create < Trailblazer::Operation
    step ->(options, a:nil, **) { options["a"] = a }
    step Callable
    step Implementation.method(:c)
    step :d
    step [ MyMacro, {} ] # TODO: test name

    def d(options, d:nil, **)
      options["d"] = d
    end
  end

  it { Create.({}, a: 1, b: 2, c: 3, d: 4, e: 5).inspect("a", "b", "c", "d", "e").must_equal "<Result:true [1, 2, 3, 4, 5] >" }

  it { Trailblazer::Operation::Inspect.call(Create).gsub(/0x[\w]+/, "").must_equal %{[>#<Proc:@test/step_test.rb:25 (lambda)>,>StepTest::Callable,>#<Method: StepTest::Implementation.c>,>d,>]} }

  #---
  #- step :whatever, name: :validate
  #- step MyMacro, name: :validate
  #- step [MyMacro, name: :validate], name: "Best!"
  class Index < Trailblazer::Operation
    step :validate!, name: "my validate"
    step :persist!
    step [ MyMacro, name: "I win!" ]
    step [ MyMacro, name: "I win!" ], name: "No, I do!"
  end

  it { Trailblazer::Operation::Inspect.call(Index).must_equal %{[>my validate,>persist!,>I win!,>No, I do!]} }
end
