module Trailblazer
  class Operation
    module Wtf
      def wtf?(ctx = nil, options_for_invoke = {}, **options) # DISCUSS: should we allow passing a positional hash for ctx?
        call(ctx, {args_compiler: Developer::Wtf::Rly::Invoke::Compiler, **options_for_invoke}, **options)
      end

      def rly?(ctx = nil, options_for_invoke = {}, **options)
        call(ctx, {args_compiler: Developer::Wtf::Invoke::Compiler, **options_for_invoke}, **options)
      end
    end
  end
end
