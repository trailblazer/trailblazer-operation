module Trailblazer
  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, skills, etc.
  #
  # per default, an operation has a binary result: success/invalid
  class Operation
    VERSION = "1.2.0"

    # we want the initializer and the ::call method.
    require "trailblazer/operation/generic"
    include Generic               # #initialize, #call, #process.
    extend Generic::ClassMethods  # ::call, ::build_operation.

    # we want the skill dependency-mechanism.
    require "trailblazer/operation/skill"
    include Trailblazer::Operation::Skill
  end
end
