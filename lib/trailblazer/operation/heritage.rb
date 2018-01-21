module Trailblazer
  # This is copied from the Declarative gem. This might get removed in favor of a real heritage gem.
  class Operation
    class Heritage < Array
      # Record inheritable assignments for replay in an inheriting class.
      def record(method, *args, &block)
        self << { method: method, args: args, block: block }
      end

      # Replay the recorded assignments on inheritor.
      # Accepts a block that will allow processing the arguments for every recorded statement.
      def call(inheritor, &block)
        each { |cfg| call!(inheritor, cfg, &block) }
      end

    private
      def call!(inheritor, cfg)
        yield cfg if block_given? # allow messing around with recorded arguments.

        inheritor.send(cfg[:method], *cfg[:args], &cfg[:block])
      end

      module Accessor
        def heritage
          @heritage ||= Heritage.new
        end
      end
    end
  end
end
