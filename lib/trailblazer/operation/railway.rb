require "trailblazer/operation/result"
require "trailblazer/circuit"

module Trailblazer
  # Operations is simply a thin API to define, inherit and run circuits by passing the options object.
  # It encourages the linear railway style (http://trb.to/gems/workflow/circuit.html#operation) but can
  # easily be extend for more complex workflows.
  class Operation
    # End event: All subclasses of End:::Success are interpreted as "success"?
    module Railway
      def self.included(includer)
        includer.extend ClassMethods # ::call, ::inititalize_pipetree!
        includer.extend DSL

        includer.initialize_activity!
      end

      # This is code run at compile-time and can be slow.
      module DSL
        def success(proc, options={}); add( args_for_pass(self["__activity__"], proc, options) ); end
        def failure(proc, options={}); add( args_for_fail(self["__activity__"], proc, options) ); end
        def step   (proc, options={}); add( args_for_step(self["__activity__"], proc, options) ); end

        # hooks to override.
        def args_for_pass(*args); Activity.args_for_pass(*args); end
        def args_for_fail(*args); Activity.args_for_fail(*args); end
        def args_for_step(*args); Activity.args_for_step(*args); end

      private
        # @api private
        # 1. Processes the step API's options (such as `:override` of `:before`).
        # 2. Uses `Sequence.alter!` to maintain a linear array representation of the circuit's tasks.
        #    This is then transformed into a circuit/Activity. (We could save this step with some graph magic)
        # 3. Returns a new Activity instance.
        def add(step_args)
          heritage.record(:add, step_args)

          proc, options = process_args(*step_args.original_args)

          # actual circuit task.
          task = Activity::Step(proc, *step_args.args_for_Step)

          # insert Step into Sequence (append, replace, before, etc.)
          sequence_row = Sequence::StepRow.new(task, options, *step_args)

          # 1. insert Step into Sequence (append, replace, before, etc.)
          self["__sequence__"].alter!(options, sequence_row)

          # 2. transform sequence to Activity
          # 3. save Activity in operation
          self["__activity__"] = self["__sequence__"].to_activity(self["__activity__"])
        end

        private
        # DSL option processing: proc/macro, :override
        def process_args(proc, options)
          _proc, _options = deprecate_input_for_macro!(proc, options) # FIXME: make me better removable!!!!!!!!!!!!!!!
          _proc, _options = normalize_args(proc, options) # handle step/macro args.

          options = _options.merge(options)
          options = options.merge(replace: options[:name]) if options[:override] # :override

          [ _proc, options ]
        end

        # Decompose single array from macros or set default name for user step.
        def normalize_args(proc, options)
          proc.is_a?(Array) ?
            proc :                   # macro
            [ proc, { name: proc } ] # user step
        end

        def deprecate_input_for_macro!(proc, options) # TODO: REMOVE IN 2.2.
          return proc, options unless proc.is_a?(Array)
          proc, options = *proc
          return proc, options unless proc.arity == 2 # FIXME: what about callable objects?

          warn "[Trailblazer] Macros with API (input, options) are deprecated. Please use the signature (options, **) just like in normal steps."
          # Execute the user step with TRB's kw args.
          proc = ->(direction, options, flow_options) do
            result = step.(flow_options[:context], options)
          end

          return proc, options
        end
      end # DSL

      module ClassMethods
        # Top-level, this method is called when you do Create.() and where
        # all the fun starts, ends, and hopefully starts again.
        def call(options)
          activity = self["__activity__"] # FIXME: rename to activity, deprecate ["__activity__"].inspect

          last, operation, flow_options = activity.(activity[:Start], options, context: new) # TODO: allow different context.

          # Result is successful if the activity ended with the "right" End event.
          Result.new(last.kind_of?(End::Success), options)
        end

        def initialize_activity!
          heritage.record :initialize_activity!

          self["__sequence__"]  = Sequence.new
          self["__activity__"] = InitialActivity()
        end

        private
        # The initial Activity with no-op wiring.
        def InitialActivity
          # mutable declarative data structure to collect all events for an operation's Circuit.
          events  = {
            end: {
              right: End::Success.new(:right),
              left:  End::Failure.new(:left)
            }
          }

          Circuit::Activity({}, events) do |evt|
            { evt[:Start] => { Circuit::Right => evt[:End, :right], Circuit::Left => evt[:End, :left] } }
          end
        end
        # attr_reader :__activity__
      end

      module End
        class Success < Circuit::End; end
        class Failure < Circuit::End; end
      end
    end


    # Allows defining dependencies and inject/override them via runtime options, if desired.
    class Railway::Step
      def initialize(step, dependencies={})
        @step, @dependencies = step, dependencies
      end

      def call(input, options)
        @dependencies.each { |k, v| options[k] ||= v } # not sure i like this, but the step's API is cool.

        @step.(input, options)
      end
    end
  end
end

require "trailblazer/operation/activity"
require "trailblazer/operation/sequence"
