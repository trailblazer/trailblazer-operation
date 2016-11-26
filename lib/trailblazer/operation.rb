require "declarative" # FIXME: here?
require "trailblazer/operation/skill"
require "trailblazer/operation/pipetree"
require "trailblazer/operation/generic"
require "trailblazer/operation/macro"

module Trailblazer
  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, skills, etc.
  class Operation
    extend Declarative::Heritage::Inherited
    extend Declarative::Heritage::DSL

    extend Skill::Accessors # ::[] and ::[]=

    include Pipetree        # ::call, ::|
    # we want the skill dependency-mechanism.
    extend Skill::Call      # ::call
    extend Skill::Call::Positional # ::call(params, options)

    # we want the initializer and the ::call method.
    include Generic         # #initialize, #call, #process.
  end
end
