require "trailblazer/developer"

module Trailblazer
  class Operation
    module Wtf
      def wtf?(options)
        call_with_public_interface(options, {}, invoke_class: Developer::Wtf)
      end
    end
  end
end
