require "trailblazer/developer"

module Trailblazer
  class Operation
    module Wtf
      def wtf?(options)
        invoke_with_public_interface(options, **Trailblazer::Developer::Wtf.options_for_canonical_invoke)
      end
    end
  end
end
