module Trailblazer
  class Operation
    module Wtf
      def wtf?(ctx = nil, options_for_invoke = {}, **options) # DISCUSS: should we allow passing a positional hash for ctx?
        call(ctx, {args_compiler: config.args_compiler_for_debugging, only_business_nodes: true, **options_for_invoke}, **options)
      end

      def rly?(ctx = nil, **options)
        wtf?(ctx, {only_business_nodes: false}, **options)
      end
    end
  end
end
