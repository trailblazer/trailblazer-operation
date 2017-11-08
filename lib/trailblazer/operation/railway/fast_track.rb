module Trailblazer
  module Operation::Railway
    # Implements the fail_fast/pass_fast logic by connecting each task to the two
    # special end events.
    module FastTrack
      def self.included(includer)
        includer.extend(DSL)
      end

      module DSL
        # TODO: how to make this better overridable without super?

        def initialize_ends!(dependencies)
          super
          dependencies.add( "End.fail_fast", [ [:fail_fast], Class.new(End::Failure).new(:fail_fast), {}, {} ], group: :end )
          dependencies.add( "End.pass_fast", [ [:pass_fast], Class.new(End::Success).new(:pass_fast), {}, {} ], group: :end )
        end

        def default_task_outputs(options)
          return super.merge( FailFast => { role: :fail_fast }, PassFast => { role: :pass_fast } ) if options[:fast_track]
          super
        end

        def seqargs_for_step(options)
          magnetic_to, connect_to = super

          connect_to = connect_to.merge( success: :pass_fast ) if options[:pass_fast]
          connect_to = connect_to.merge( failure: :fail_fast ) if options[:fail_fast]
          connect_to = connect_to.merge( fail_fast: :fail_fast, pass_fast: :pass_fast ) if options[:fast_track]

          [ magnetic_to, connect_to ]
        end

        def seqargs_for_pass(options)
          magnetic_to, connect_to = super

          connect_to = connect_to.merge( success: :pass_fast, failure: :pass_fast )     if options[:pass_fast]
          connect_to = connect_to.merge( fail_fast: :fail_fast, pass_fast: :pass_fast ) if options[:fast_track]

          [ magnetic_to, connect_to ]
        end

        def seqargs_for_fail(options)
          magnetic_to, connect_to = super

          connect_to = connect_to.merge( failure: :fail_fast, success: :fail_fast )     if options[:fail_fast]
          connect_to = connect_to.merge( fail_fast: :fail_fast, pass_fast: :pass_fast ) if options[:fast_track]

          [ magnetic_to, connect_to ]
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
