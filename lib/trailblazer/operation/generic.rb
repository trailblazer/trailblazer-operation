module Trailblazer
  module Operation::Generic
    module ClassMethods
      # The default API is Operation.(params, dependencies={})
      def call(params={}, *options)
        build_operation(params, *options).call(params)
      end

      # DISCUSS: rename to build?
      def build_operation(params, *options)
        new(params, *options)
      end
    end

    def initialize(params, instance_attrs={}) # note that we do *not* call super.
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
