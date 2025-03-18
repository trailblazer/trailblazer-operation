require "trailblazer/developer"

module Trailblazer
  class Operation
    module Wtf
      def wtf?(options)
        invoke_with_public_interface(options, invoke_method: Trailblazer::Developer::Wtf.method(:invoke))
      end
    end
  end
end
