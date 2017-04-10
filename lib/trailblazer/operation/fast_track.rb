module Trailblazer
  module Operation::Railway
    # Implements the fail_fast/pass_fast logic by connecting each task to the two
    # special end events.
    module FastTrack
      # modules for declarative APIs are fine.
      def self.included(includer)
        # add additional end events to the circuit.
        includer.extend(DSL)
        includer.initialize_event!

      end


      module DSL
        def initialize_event! # FIXME: make this cooler!
          heritage.record :initialize_event!

          self["railway_extra_events"] = self["railway_extra_events"].merge(
            pass_fast: Class.new(End::Success).new(:pass_fast),
            fail_fast: Circuit::End.new(:fail_fast)
          )
        end

        # DISCUSS: any way to override DSL methods without that redundancy? inject/normalize? options
        def success(*args); add(:right, Circuit::Right, [], *args) end
        def failure(*args); add(:left,  Circuit::Left,  [], *args) end
        def step(*args)
          # connect task to End.left, End.fail_fast and End.pass_fast.
          add(:right, Circuit::Right, [[Circuit::Left, :left], [FailFast, :fail_fast], [PassFast, :pass_fast]], *args)
        end
        # only step needs both additional connections.
        # failure only needs fail fast connection (and returner when :fail_fast). dito for pass
      end
    end

    module_function
    def fail!     ; Circuit::Left  end
    def fail_fast!; FailFast       end
    def pass!     ; Circuit::Right end
    def pass_fast!; PassFast       end

    private
    # Direction signals.
    class FailFast < Circuit::Left;  end
    class PassFast < Circuit::Right; end
  end
end
