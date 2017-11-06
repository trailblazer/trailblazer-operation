require "test_helper"

class SequenceOptionsTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step :first
    step :log_success!, group: :end, before: "End.success" #prepend: true

    step :second
    step :third

    fail :log_errors!, id: "log_errors"

    #~ignore
    def first(options, **)
      options["row"] = [:a]
    end

    # our success "end":
    def log_success!(options, **)
      options["row"] << :z
    end

    # 2
    def second(options, **)
      options["row"] << :b
    end

    # 3
    def third(options, **)
      options["row"] << :c
    end

    def log_errors!(options, **)
      options["row"] << :f
    end
    #~ignore end
  end
  #:doormat-before end

  # it { pp Create['__sequence__'].to_a }
  it { Create.({}, "b_return" => false,
                                  ).inspect("row").must_equal %{<Result:true [[:a, :b, :c, :z]] >} }
end

class DoormatStepDocsTest < Minitest::Spec
  #:doormat-before
  class Create < Trailblazer::Operation
    step :first
    step :log_success!

    step :second, before: :log_success!
    step :third,  before: :log_success!

    fail :log_errors!, id: "log_errors"

    #~ignore
    def first(options, **)
      options["row"] = [:a]
    end

    # our success "end":
    def log_success!(options, **)
      options["row"] << :z
    end

    # 2
    def second(options, **)
      options["row"] << :b
    end

    # 3
    def third(options, **)
      options["row"] << :c
    end

    def log_errors!(options, **)
      options["row"] << :f
    end
    #~ignore end
  end
  #:doormat-before end

  # it { pp F['__sequence__'].to_a }
  it { Create.({}, "b_return" => false,
                                  ).inspect("row").must_equal %{<Result:true [[:a, :b, :c, :z]] >} }
end

# class DoormatInheritanceTest < Minitest::Spec
#   #:doormatx-before-inheritance
#   class Base < Trailblazer::Operation
#     step :log_success!
#     fail :log_errors!
#     #~ignored
#     # our success "end":
#     def log_success!(options, **)
#       options["row"] << :z
#     end

#     def log_errors!(options, **)
#       options["row"] << :f
#     end
#     #~ignored end
#   end
#   #:doormatx-before-inheritance end

#   #:doormat-before-inheritance-sub
#   class Create < Base
#     step :first, before: :log_success!
#     step :second, before: :log_success!
#     step :third,  before: :log_success!
#     #~ignoredd
#     def first(options, **)
#       options["row"] = [:a]
#     end

#     # 2
#     def second(options, **)
#       options["row"] << :b
#     end

#     # 3
#     def third(options, **)
#       options["row"] << :c
#     end
#     #~ignoredd end
#   end
#   #:doormat-before-inheritance-sub end

#   # it { pp F['__sequence__'].to_a }
#   it { Create.({}, "b_return" => false,
#                                   ).inspect("row").must_equal %{<Result:true [[:a, :b, :c, :z]] >} }
# end

