require "test_helper"
require "dry/container"

class DryContainerTest < Minitest::Spec
  my_container = Dry::Container.new
  my_container.register("user_repository", -> { Object })
  my_container.namespace("contract") do
    register("create") { Array }
  end

  class Create < Trailblazer::Operation
  end

  it { Create.({}, {}, my_container)["user_repository"].must_equal Object }
  it { Create.({}, {}, my_container)["contract.create"].must_equal Array }
  # also allows our own options PLUS containers.
  it { Create.({}, { "model" => String }, my_container)["model"].must_equal String }
  it { Create.({}, { "model" => String }, my_container)["user_repository"].must_equal Object }
  it { Create.({}, { "user_repository" => Fixnum }, my_container)["user_repository"].must_equal Fixnum }
end
