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


        def output_mappings_for_pass(task, options)
          target = [:End, :pass_fast]

          return super.merge(success: target, failure: target) if options[:pass_fast]
          super

          # {
          #   :success => [:End, :success],
          #   :failure => [:End, :success]
          # }
        end

        def output_mappings_for_fail(task, options)
          target = [:End, :fail_fast]

          return super.merge(failure: target, success: target) if options[:fail_fast]
          super
        end

        def output_mappings_for_step(task, options)
          step_options = {
            success: output_mappings_for_pass(task, options)[:success],
            failure: output_mappings_for_fail(task, options)[:failure]
          }

          super.merge(step_options)
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
