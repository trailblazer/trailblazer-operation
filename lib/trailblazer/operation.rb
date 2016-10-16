module Trailblazer
  class Operation
    VERSION = "1.2.0"

    class << self
      # The default API is Operation.(params, dependencies={})
      def call(params={}, *options)
        build_operation(params, *options).call(params)
      end

      def build_operation(params, *options)
        new(params, *options)
      end
    end

    def initialize(params, instance_attrs={})
      @valid = true
      @instance_attrs = instance_attrs
    end

    def call(params)
      result(process(params))#(*)
    end

    # dependency injection interface
    require "uber/delegates"
    extend Uber::Delegates
    delegates :@instance_attrs, :[], :[]=

  private
    def process(*)
    end

    # Compute the result object.
    def result(returned, *)
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
