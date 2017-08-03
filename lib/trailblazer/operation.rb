require "forwardable"
require "declarative"
require "trailblazer/circuit"
require "trailblazer/operation/public_call"      # TODO: Remove in 3.0.
require "trailblazer/operation/skill"
require "trailblazer/operation/deprecated_macro" # TODO: remove in 2.2.
require "trailblazer/operation/result"
require "trailblazer/operation/railway"
require "trailblazer/operation/dsl"
require "trailblazer/operation/graph"
require "trailblazer/operation/sequence"
require "trailblazer/operation/fast_track"
require "trailblazer/operation/task_wrap"
require "trailblazer/operation/injection"
require "trailblazer/operation/trace"

module Trailblazer
  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, skills, etc.
  class Operation
    # support for declarative inheriting (e.g. the circuit).
    extend Declarative::Heritage::Inherited
    extend Declarative::Heritage::DSL

    extend Skill::Accessors        # ::[] and ::[]=

    include Railway                # ::call, ::step, ...
    # include Railway::FastTrack
    include Railway::TaskWrap

    # we want the skill dependency-mechanism.
    # extend Skill::Call             # ::call(params: .., current_user: ..)
    extend PublicCall              # ::call(params, { current_user: .. })

    extend Trace                   # ::trace
  end
end

require "trailblazer/operation/inspect"
