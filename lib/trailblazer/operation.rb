module Trailblazer
  class Operation
    VERSION = "1.2.0"

    class << self
      def call(**args)
        # TODO: builder!
        build_operation(args).call(args[:params] || {})
      end

      def build_operation(**args)
        new(**args)
      end
    end

    def initialize(**args)
      @valid = true
    end

    def call(**args) # receives args[:params]
      result(process(args))#(*)
    end

  private
    def process(**)
    end

    # Compute the result object.
    def result(returned, **)
      { valid: @valid, operation: self }#.merge(returned)
    end

    # DISCUSS: do we want that per default?
    module State
      module Valid
        def invalid!
          @valid = false
        end
      end
    end
    include State::Valid # #invalid! - should we have that per default?
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
