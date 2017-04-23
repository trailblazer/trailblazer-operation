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

          fast_track_events = {
            end: {
              pass_fast: Class.new(End::Success).new(:pass_fast),
              fail_fast: Class.new(End::Failure).new(:fail_fast)
            }
          }

          self["__activity__"] = Circuit::Activity::Rewrite(self["__activity__"], {}, fast_track_events) { |*| }
        end

        def args_for_pass(activity, proc, options)
          direction = options[:pass_fast] ? PassFast : Circuit::Right # task will emit PassFast or Right, depending on options.

          super.tap do |args|
            args.connections    = [[PassFast, activity[:End, :pass_fast]]]
            args.args_for_Step = [direction, direction]
          end
        end

        def args_for_fail(activity, proc, options)
          direction = options[:fail_fast] ? FailFast : Circuit::Left # task will emit PassFast or Right, depending on options.

          # DISCUSS: should this also link to right, pass_fast etc? Because this will fail now.
          # CONNECTED TO Left=>END.LEFT AND FailFast=>END.FAIL_FAST
          super.tap do |args|
            args.connections = [[FailFast, activity[:End, :fail_fast]]]
            args.args_for_Step = [direction, direction]
          end
        end


        def args_for_step(activity, proc, options)
          direction_on_false = options[:fail_fast] ? FailFast : Circuit::Left
          direction_on_true  = options[:pass_fast] ? PassFast : Circuit::Right

          # DISCUSS: should this also link to right, pass_fast etc?
          # CONNECTED TO Left=>END.LEFT AND FailFast=>END.FAIL_FAST
          super.tap do |args|
            args.connections = [[Circuit::Left, activity[:End, :left]], [FailFast, activity[:End, :fail_fast]], [PassFast, activity[:End, :pass_fast]]]
           args.args_for_Step = [direction_on_true, direction_on_false]
         end
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
