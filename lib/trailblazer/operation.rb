require "forwardable"
require "declarative"
require "trailblazer/operation/skill"
require "trailblazer/operation/pipetree"

module Trailblazer
  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, skills, etc.
  class Operation
    # support for declarative inheriting (e.g. the circuit).
    extend Declarative::Heritage::Inherited
    extend Declarative::Heritage::DSL

    extend Skill::Accessors        # ::[] and ::[]=

    include Pipetree               # ::call, ::step, ...
    # we want the skill dependency-mechanism.
    extend Skill::Call             # ::call(params: {}, current_user: ..)
    extend Skill::Call::Positional # ::call(params, options)
  end
end
