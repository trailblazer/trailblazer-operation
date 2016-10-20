module Trailblazer
  class Operation
    VERSION = "1.2.0"

    class << self
      # The default API is Operation.(params, dependencies={})
      def call(params={}, *options)
        build_operation(params, *options).call(params)
      end

      # DISCUSS: rename to build?
      def build_operation(params, *options)
        new(params, *options)
      end
    end

    def initialize(params, instance_attrs={})
      @instance_attrs = instance_attrs
      result[:valid]  = true
    end

    def call(params)
      result!(process(params))#(*)
    end

    # dependency injection interface
    require "uber/delegates"
    extend Uber::Delegates
    delegates :@instance_attrs, :[], :[]=

  private
    def process(*)
    end

    # Compute the result object.
    # Feel free to override this.
    def result!(returned, *)
      result.merge({ operation: self })#.merge(returned)
    end

    def result
      @result ||= {}
    end
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
