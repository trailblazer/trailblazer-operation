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
    step [ MyMacro, {} ]

    def d(options, d:nil, **)
      options["d"] = d
    end
  end

  it { Create.({}, a: 1, b: 2, c: 3, d: 4, e: 5).inspect("a", "b", "c", "d", "e").must_equal "<Result:true [1, 2, 3, 4, 5] >" }

  it { Trailblazer::Operation::Inspect.(Create).gsub(/0x[\w]+/, "").must_equal %{[>#<Proc:@test/step_test.rb:25 (lambda)>,>StepTest::Callable,>#<Method: StepTest::Implementation.c>,>d,>]} }

  #---
  #- :before, :after, :replace, :delete
  class A < Trailblazer::Operation
    step :a!
    def a!(options, **); options["a"] = 1; end
  end

  class B < A
    step :b!, before: :a!
    step :c!, before: :a!
    step :d!, after:  :b!
  end

  it { Trailblazer::Operation::Inspect.(B).must_equal %{[>b!,>d!,>c!,>a!]} }

  class C < B
    step :e!, replace: :c!
    step nil, delete: :d!
  end

  it { Trailblazer::Operation::Inspect.(C).must_equal %{[>b!,>e!,>a!]} }
# todo: :override

  #---
  #- :name
  #-   step :whatever, name: :validate
  class Index < Trailblazer::Operation
    step :validate!, name: "my validate"
    step :persist!
    step [ MyMacro, name: "I win!" ]
    step [ MyMacro, name: "I win!" ], name: "No, I do!"
  end

  it { Trailblazer::Operation::Inspect.(Index).must_equal %{[>my validate,>persist!,>I win!,>No, I do!]} }

  #---
  #- inheritance
  class New < Create
  end

  it { Trailblazer::Operation::Inspect.(New).gsub(/0x[\w]+/, "").must_equal %{[>#<Proc:@test/step_test.rb:25 (lambda)>,>StepTest::Callable,>#<Method: StepTest::Implementation.c>,>d,>]} }

  class Update < Create
    step :after_save!
  end

  it { Trailblazer::Operation::Inspect.(Update).gsub(/0x[\w]+/, "").must_equal %{[>#<Proc:@test/step_test.rb:25 (lambda)>,>StepTest::Callable,>#<Method: StepTest::Implementation.c>,>d,>,>after_save!]} }
end
