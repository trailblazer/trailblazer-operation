module Trailblazer
  module Operation::Generic
    module ClassMethods
      # TODO: move this to compat
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
      self[:valid]  = true
    end

    def call(params)
      process(params)
      self # DISCUSS: do we want this here?
    end

    # dependency injection interface
    require "uber/delegates"
    extend Uber::Delegates
    delegates :@instance_attrs, :[], :[]=

  private
    def process(*)
    end
  end
end
