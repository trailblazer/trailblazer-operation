class Trailblazer::Operation
  module Macro
    Configuration = Struct.new(:mod, :args, :block) do
      include Macro # mark it, so that ::| thinks this is a step module.

      def import!(operation, import)
        mod.import!(operation, import, *args)
      end
    end

    def [](*args, &block)
      # When called like Builder["builder.crud"], create a proxy
      # object and Pipeline::| calls #import! on it.
      Configuration.new(self, args, block)
    end
  end
end
