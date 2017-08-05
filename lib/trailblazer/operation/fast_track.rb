module Trailblazer
  module Operation::Railway
    # Implements the fail_fast/pass_fast logic by connecting each task to the two
    # special end events.
    module FastTrack
      # modules for declarative APIs are fine.
      def self.included(includer)
        # add additional end events to the circuit.
        includer.extend(DSL)
        # includer.initialize_fast_track_events!
      end

      module DSL
        def InitialActivity # FIXME: make this cooler!
          super.tap do |start|
            end_for_pass_fast = Class.new(End::Success).new(:pass_fast)
            end_for_fail_fast = Class.new(End::Failure).new(:fail_fast)

            start.attach!( target: [ end_for_pass_fast, id: [:End, :pass_fast] ], edge: [ PassFast, type: :railway ] )
            start.attach!( target: [ end_for_fail_fast, id: [:End, :fail_fast] ], edge: [ FailFast, type: :railway ] )
          end
        end

        def args_for_pass(proc, options)
          super.tap do |args|
            if options[:pass_fast]
              args.args_for_task_builder = [PassFast, PassFast] # always go to End.pass_fast, no matter if truthy or falsey.

              insert_before_cfg = args.wirings[0]
              insert_before_cfg[2].delete(:outgoing) # FIXME: sucks

              # insert_before_cfg[2][:outgoing] = [PassFast, type: :railway]


              args.wirings << [ :connect!, source: "fixme!!!", edge: [ PassFast, type: :railway ], target: [:End, :pass_fast] ]
            else
              args.wirings << [ :connect!, source: "fixme!!!", edge: [ PassFast, type: :railway ], target: [:End, :pass_fast] ]
            end
          end
        end

        def args_for_fail(proc, options)
          super.tap do |args|
            if options[:fail_fast]
              args.args_for_task_builder = [FailFast, FailFast] # always go to End.pass_fast, no matter if truthy or falsey.

              insert_before_cfg = args.wirings[0]
              insert_before_cfg[2][:outgoing] = [FailFast, type: :railway]
            else
              args.wirings << [ :connect!, source: "fixme!!!", edge: [ FailFast, type: :railway ], target: [ :End, :pass_fast ] ]
            end
          end
        end

        def args_for_step(proc, options)
          direction_on_false = options[:fail_fast] ? FailFast : Circuit::Left
          direction_on_true  = options[:pass_fast] ? PassFast : Circuit::Right

          super.tap do |args|
            args.args_for_task_builder = [direction_on_true, direction_on_false]

            # if options[:pass_fast]

            #   insert_before_cfg = args.wirings[0]
            #   insert_before_cfg[2][:outgoing] = [PassFast, type: :railway]
            # else
              args.wirings << [ :connect!, source: "fixme!!!", edge: [ PassFast, type: :railway ], target: [ :End, :pass_fast ] ]
              args.wirings << [ :connect!, source: "fixme!!!", edge: [ FailFast, type: :railway ], target: [ :End, :fail_fast ] ]
            # end

            # if options[:fail_fast]
            #   args.args_for_task_builder = [FailFast, FailFast] # always go to End.pass_fast, no matter if truthy or falsey.

            #   insert_before_cfg = args.wirings[0]
            #   insert_before_cfg[2][:outgoing] = [FailFast, type: :railway]
            # else
            #   args.wirings << [ :connect!, source: "fixme!!!", edge: [ FailFast, type: :railway ], target: [ :End, :pass_fast ] ]
            # end


            # FIXME: edges we don't want, when pass_fast set!
          end
        end

        # def args_for_step(proc, options)
        #   direction_on_false = options[:fail_fast] ? FailFast : Circuit::Left
        #   direction_on_true  = options[:pass_fast] ? PassFast : Circuit::Right

        #   # DISCUSS: should this also link to right, pass_fast etc?
        #   # CONNECTED TO Left=>END.LEFT AND FailFast=>END.FAIL_FAST
        #   super.tap do |args|
        #     args.connections = [[Circuit::Left, [:End, :left]], [FailFast, [:End, :fail_fast]], [PassFast, [:End, :pass_fast]]]
        #    args.args_for_task_builder = [direction_on_true, direction_on_false]
        #  end
        # end
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
