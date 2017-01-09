require "test_helper"

class OperationSkillTest < Minitest::Spec
  class Create < Trailblazer::Operation
  end

  # no dependencies provided.
  it { Create.()[:not_existent].must_equal nil }
  # dependencies provided.
  it { Create.({}, contract: Object)[:not_existent].must_equal nil }
  it { Create.({}, contract: Object)[:contract].must_equal Object }
end

class OperationCompetenceTest < Minitest::Spec
  # Operation#[]
  # Operation#[]=
  # arbitrary options can be saved via Op#[].
  class Create < Trailblazer::Operation
    success :call

    def call(*)
      self["drink"] = "Little Creatures"
      self["drink"]
    end
  end

  it { Create.()["drink"].must_equal "Little Creatures" }
  # instance can override constructor options.
  it { Create.({}, "drink" => "Four Pines")["drink"].must_equal "Little Creatures" }
  # original hash doesn't get changed.
  it do
    Create.({}, hash = { "drink" => "Four Pines" })
    hash.must_equal( { "drink" => "Four Pines" })
  end


  # Operation::[]
  # Operation::[]=
  class Update < Trailblazer::Operation
    success :call

    self["drink"] = "Beer"

    def call(*)
      self["drink"]
    end
  end

  it { Update["drink"].must_equal "Beer" }

  # class-level are available on instance-level via Op#[]
  it { Update.()["drink"].must_equal "Beer" }

  # runtime constructor options can override class-level.
  it { Update.({}, "drink" => "Little Creatures")["drink"].must_equal "Little Creatures" }

  # instance can override class-level
  class Delete < Trailblazer::Operation
    success :call

    self["drink"] = "Beer"

    def call(*)
      self["drink"] = "Little Creatures"
      self["drink"]
    end
  end

  # Op#[]= can override class-level...
  it { Delete.()["drink"].must_equal "Little Creatures" }
  # ...but it doesn't change class-level.
  it { Delete["drink"].must_equal "Beer" }

  # we don't really need this test.
  class Reward < Trailblazer::Operation
    self["drink"] = "Beer"
  end

  it { Reward.()["drink"].must_equal "Beer" }
end

# {
#   user_repository: ..,
#   current_user: ..,
# }


# 1. initialize(params, {})
# 2. extend AutoInject[] shouldn't override constructor but simply pass injected dependencies in second arg (by adding dependencies to hash).
