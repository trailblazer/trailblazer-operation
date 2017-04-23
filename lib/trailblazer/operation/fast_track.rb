module Trailblazer
  module Operation::Railway
    # Implements the fail_fast/pass_fast logic by connecting each task to the two
    # special end events.
    module FastTrack
      # modules for declarative APIs are fine.
      def self.included(includer)
        # add additional end events to the circuit.
        includer.extend(DSL)
        includer.initialize_fast_track_events!
      end


      module DSL
        def initialize_fast_track_events! # FIXME: make this cooler!
          heritage.record :initialize_fast_track_events!

          self["__events__"][:end] = self["__events__"][:end].merge(
              pass_fast: Class.new(End::Success).new(:pass_fast),
              fail_fast: Circuit::End.new(:fail_fast)
          )
        end

        # # DISCUSS: any way to override DSL methods without that redundancy? inject/normalize? options
        def args_for_pass(step, options={})
          direction = options[:pass_fast] ? PassFast : Circuit::Right # task will emit PassFast or Right, depending on options.

          super.tap { |args| args[2] = [[PassFast, self["__events__"][:end][:pass_fast]]]; args[3] = [direction, direction] }
        end

        def args_for_fail(step, options={})
          direction = options[:fail_fast] ? FailFast : Circuit::Left # task will emit PassFast or Right, depending on options.

          # DISCUSS: should this also link to right, pass_fast etc? Because this will fail now.
          # CONNECTED TO Left=>END.LEFT AND FailFast=>END.FAIL_FAST
          super.tap { |args| args[2] = [[FailFast, self["__events__"][:end][:fail_fast]]]; args[3] = [direction, direction] }
        end


        def args_for_step(step, options={})
          direction_on_false = options[:fail_fast] ? FailFast : Circuit::Left
          direction_on_true  = options[:pass_fast] ? PassFast : Circuit::Right

          # DISCUSS: should this also link to right, pass_fast etc?
          # CONNECTED TO Left=>END.LEFT AND FailFast=>END.FAIL_FAST
          super.tap { |args| args[2] = [[Circuit::Left, self["__events__"][:end][:left]], [FailFast, self["__events__"][:end][:fail_fast]], [PassFast, self["__events__"][:end][:pass_fast]]]; args[3] = [direction_on_true, direction_on_false] }
        end
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
