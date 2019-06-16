require "test_helper"

class TemplateWithGroupTest < Minitest::Spec
  module Memo; end

  #:template
  class Memo::Operation < Trailblazer::Operation
    step :log_call, group: :start
    step :log_success,  group: :end, before: "End.success"
    fail :log_errors,   group: :end, before: "End.failure"
    #~tmethods

    # our success "end":
    def log_call(options, **)
      options["row"] = [:a]
    end

    # our success "end":
    def log_success(options, **)
      options["row"] << :z
    end

    def log_errors(options, **)
      options["row"] << :f
    end
    #~tmethods end
  end
  #:template end

  #:template-user
  class Memo::Create < Memo::Operation
    step :create_model
    step :validate
    step :save
    #~meths
    def create_model(options, **)
      options["row"] << :l
    end

    def validate(options, **)
      options["row"] << :b
    end

    def save(options, **)
      options["row"] << :c
    end
    #~meths end
  end
  #:template-user end

  # it { pp F['__sequence__'].to_a }
  it {
    skip
    Memo::Create.(params: {}, "b_return" => false).inspect("row").must_equal %{<Result:true [[:a, :l, :b, :c, :z]] >}
  }
end

class DoormatWithGroupTest < Minitest::Spec
  module Memo; end

  #:doormat-group
  class Memo::Create < Trailblazer::Operation
    step :create_model
    step :log_success, group: :end, before: "End.success"

    step :validate
    step :save

    fail :log_errors, group: :end, before: "End.failure"
    #~methods
    def create_model(options, **)
      options["row"] = [:a]
    end

    # our success "end":
    def log_success(options, **)
      options["row"] << :z
    end

    # 2
    def validate(options, **)
      options["row"] << :b
    end

    # 3
    def save(options, **)
      options["row"] << :c
    end

    def log_errors(options, **)
      options["row"] << :f
    end
    #~methods end
  end
  #:doormat-group end

  # it { pp F['__sequence__'].to_a }
  it {
    skip
    Memo::Create.(params: {}, "b_return" => false).inspect("row").must_equal %{<Result:true [[:a, :b, :c, :z]] >}
  }
end

class DoormatStepDocsTest < Minitest::Spec
  module Memo; end

  #:doormat-before
  class Memo::Create < Trailblazer::Operation
    step :create_model
    step :log_success

    step :validate, before: :log_success
    step :save,     before: :log_success

    fail :log_errors
    #~im
    def create_model(options, **)
      options["row"] = [:a]
    end

    # our success "end":
    def log_success(options, **)
      options["row"] << :z
    end

    # 2
    def validate(options, **)
      options["row"] << :b
    end

    # 3
    def save(options, **)
      options["row"] << :c
    end

    def log_errors(options, **)
      options["row"] << :f
    end
    #~im end
  end
  #:doormat-before end

  # it { pp F['__sequence__'].to_a }
  it { Memo::Create.(params: {}, "b_return" => false).inspect("row").must_equal %{<Result:true [[:a, :b, :c, :z]] >} }
end

class DoormatInheritanceTest < Minitest::Spec
  #:doormatx-before-inheritance
  class Base < Trailblazer::Operation
    step :log_success!
    fail :log_errors!
    #~ignored
    # our success "end":
    def log_success!(options, **)
      options["row"] << :z
    end

    def log_errors!(options, **)
      options["row"] << :f
    end
    #~ignored end
  end
  #:doormatx-before-inheritance end

  #:doormat-before-inheritance-sub
  class Create < Base
    step :first, before: :log_success!
    step :second, before: :log_success!
    step :third,  before: :log_success!
    #~ignoredd
    def first(options, **)
      options["row"] = [:a]
    end

    # 2
    def second(options, **)
      options["row"] << :b
    end

    # 3
    def third(options, **)
      options["row"] << :c
    end
    #~ignoredd end
  end
  #:doormat-before-inheritance-sub end

  # it { pp F['__sequence__'].to_a }
  it { Create.("b_return" => false).inspect("row").must_equal %{<Result:true [[:a, :b, :c, :z]] >} }
end
