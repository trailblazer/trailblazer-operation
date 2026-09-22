module Trailblazer
  class Operation
    module Wtf
      def wtf?(**options)
        invoke_with_args_compiler(options, args_compiler: config.args_compiler_for_debugging)
      end
    end
  end
end
