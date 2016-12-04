class Trailblazer::Operation
  module Macro
    def [](*args, &block)
      # When called like Builder["builder.crud"], create a proxy
      # object and Pipeline::| calls #import! on it.
      [self, args, block]
    end
  end
end
