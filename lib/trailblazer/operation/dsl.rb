module Trailblazer
  module Operation::Railway
    # This is code run at compile-time and can be slow.
    module DSL
      def success(proc, options={}); add_step!(:pass, proc, options); end
      def failure(proc, options={}); add_step!(:fail, proc, options); end
      def step   (proc, options={}); add_step!(:step, proc, options); end
      # TODO: ADD PASS AND FAIL

      private
      StepArgs = Struct.new(:original_args, :incoming_direction, :connections, :args_for_Step, :insert_before)

      # Override these if you want to extend how tasks are built.
      def args_for_pass(activity, *args); StepArgs.new( args, Circuit::Right, [], [Circuit::Right, Circuit::Right], activity[:End, :right] ); end
      def args_for_fail(activity, *args); StepArgs.new( args, Circuit::Left,  [], [Circuit::Left, Circuit::Left], activity[:End, :left] ); end
      def args_for_step(activity, *args); StepArgs.new( args, Circuit::Right, [[ Circuit::Left, activity[:End, :left] ]], [Circuit::Right, Circuit::Left], activity[:End, :right] ); end

      def add_step!(type, proc, options)
        heritage.record(type, proc, options)

        activity, sequence = self["__activity__"], self["__sequence__"]

        self["__activity__"] = add(activity, sequence, send("args_for_#{type}", activity, proc, options) )
      end

      # @api private
      # 1. Processes the step API's options (such as `:override` of `:before`).
      # 2. Uses `Sequence.alter!` to maintain a linear array representation of the circuit's tasks.
      #    This is then transformed into a circuit/Activity. (We could save this step with some graph magic)
      # 3. Returns a new Activity instance.
      def add(activity, sequence, step_args, step_builder=Operation::Railway::Step) # decoupled from any self deps.
        proc, options = process_args(*step_args.original_args)

        # Wrap step code into the actual circuit task.
        task = build_task(proc, options, step_args, step_builder)

        # 1. insert Step into Sequence (append, replace, before, etc.)
        sequence.insert!(task, options, step_args)
        # 2. transform sequence to Activity
        sequence.to_activity(activity)
        # 3. save Activity in operation (on the outside)
      end

      private
      # DSL option processing: proc/macro, :override
      def process_args(proc, options)
        _proc, _options = normalize_args(proc, options) # handle step/macro args.

        options = _options.merge(options)
        options = options.merge(replace: options[:name]) if options[:override] # :override

        [ _proc, options ]
      end

      def build_task(proc, options, step_args, step_builder)
        step_builder.(proc, *step_args.args_for_Step)
      end

      # Decompose single array from macros or set default name for user step.
      def normalize_args(proc, options)
        proc.is_a?(Array) ?
          proc :                   # macro
          [ proc, { name: proc } ] # user step
      end

      module DeprecatedMacro # TODO: REMOVE IN 2.2.
        def self.call(step, on_true, on_false)
          ->(direction, options, flow_options) do
            result    = step.(flow_options[:context], options)
            direction = Step.binary_direction_for(result, on_true, on_false)

            [ direction, options, flow_options ]
          end
        end

        def build_task(proc, options, step_args, step_builder)
          original_proc, _ = step_args.original_args
          return super unless original_proc.is_a?(Array)
          original_proc = original_proc.first

          if original_proc.is_a?(Proc)
            return super if original_proc.arity != 2
          else
            return super if original_proc.method(:call).arity != 2
          end


          warn "[Trailblazer] Macros with API (input, options) are deprecated. Please use the signature (options, **) just like in normal steps. (#{proc})"
          super(proc, options, step_args, DeprecatedMacro)
        end
      end
    end # DSL
  end
end
