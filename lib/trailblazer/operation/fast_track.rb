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

          end_for_pass_fast = Class.new(End::Success).new(:pass_fast)
          end_for_fail_fast = Class.new(End::Failure).new(:fail_fast)

          @start.connect!( target: [ end_for_pass_fast, id: [:End, :pass_fast] ], edge: [ PassFast, type: :railway ] )
          @start.connect!( target: [ end_for_fail_fast, id: [:End, :fail_fast] ], edge: [ FailFast, type: :railway ] )
        end

        def args_for_pass(proc, options)
          direction = options[:pass_fast] ? PassFast : Circuit::Right # task will emit PassFast or Right, depending on options.

        # [
        #   [:insert_before!, [:End, :success], incoming: ->(edge) { edge[:type] == :railway }, node: nil, outgoing: [Circuit::Right, type: :railway] ],
        # ]

          super.tap do |args|
            # always connect task to End:pass_fast so the emitted PassFast signal from Railway#pass_fast! is wired.
            args.connections    = [ [PassFast, [:End, :pass_fast]] ]
            args.args_for_task_builder = [direction, direction]
          end
        end

        def args_for_fail(proc, options)
          direction = options[:fail_fast] ? FailFast : Circuit::Left # task will emit PassFast or Right, depending on options.

          # DISCUSS: should this also link to right, pass_fast etc? Because this will fail now.
          # CONNECTED TO Left=>END.LEFT AND FailFast=>END.FAIL_FAST
          super.tap do |args|
            args.connections = [[FailFast, [:End, :fail_fast]]]
            args.args_for_task_builder = [direction, direction]
          end
        end

        def args_for_step(proc, options)
          direction_on_false = options[:fail_fast] ? FailFast : Circuit::Left
          direction_on_true  = options[:pass_fast] ? PassFast : Circuit::Right

          # DISCUSS: should this also link to right, pass_fast etc?
          # CONNECTED TO Left=>END.LEFT AND FailFast=>END.FAIL_FAST
          super.tap do |args|
            args.connections = [[Circuit::Left, [:End, :left]], [FailFast, [:End, :fail_fast]], [PassFast, [:End, :pass_fast]]]
           args.args_for_task_builder = [direction_on_true, direction_on_false]
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
