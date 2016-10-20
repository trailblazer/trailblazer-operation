module Trailblazer
  class Operation
    VERSION = "1.2.0"

    require "trailblazer/operation/generic"
    include Generic
    extend Generic::ClassMethods
  end
end

# initialize: @result = {}
# call -> merge .process

# per default, an operation has a binary result: success/invalid
# an attempt to cleanup before 2.0 with pipetree

# TODO:
# Deprecation::Run (old semantics!)
# Make ::builds work "anywhere", without Op interface

# CHANGES:
# * Removed `Operation::[]` in favor of `Operation::()`.
# * `Operation#invalid!` doesn't accept a result anymore.
# * Removed `Operation#valid?` in favor of the result object.
