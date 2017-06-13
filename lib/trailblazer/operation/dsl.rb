module Trailblazer
  module Operation::Railway
    # WARNING: The API here is still in a state of flux since we want to provide a simple yet flexible solution.
    # This is code executed at compile-time and can be slow.
    # @note `__sequence__` is a private concept, your custom DSL code should not rely on it.

    module DSL
      def pass(proc, options={}); add_step!(:pass, proc, options); end
      def fail(proc, options={}); add_step!(:fail, proc, options); end
      def step(proc, options={}); add_step!(:step, proc, options); end
      alias_method :success, :pass
      alias_method :failure, :fail

      private
      # DSL object, mutable.
      StepArgs = Struct.new(:original_args, :incoming_direction, :connections, :args_for_TaskBuilder, :insert_before_id)

      # Override these if you want to extend how tasks are built.
      def args_for_pass(*args); StepArgs.new( args, Circuit::Right, [], [Circuit::Right, Circuit::Right], [:End, :right] ); end
      def args_for_fail(*args); StepArgs.new( args, Circuit::Left,  [], [Circuit::Left, Circuit::Left], [:End, :left] ); end
      def args_for_step(*args); StepArgs.new( args, Circuit::Right, [[ Circuit::Left, [:End, :left] ]], [Circuit::Right, Circuit::Left], [:End, :right] ); end

      # |-- compile initial act from alterations
      # |-- add step alterations
      def add_step!(type, proc, options)
        heritage.record(type, proc, options)

        # compile the arguments specific to step/fail/pass.
        args_for = send("args_for_#{type}", proc, options) # call args_for_pass/args_for_fail/args_for_step.

        # re-compile the activity with every DSL call.
        self["__activity__"] = recompile_activity( self["__activity_alterations__"], self["__sequence__"], args_for )
      end

      # @api private
      # 1. Processes the step API's options (such as `:override` of `:before`).
      # 2. Uses `Sequence.alter!` to maintain a linear array representation of the circuit's tasks.
      #    This is then transformed into a circuit/Activity. (We could save this step with some graph magic)
      # 3. Returns a new Activity instance.
      def recompile_activity(railway_alterations, sequence, step_args, task_builder=Operation::Railway::TaskBuilder) # decoupled from any self deps.
        proc, user_options = *step_args.original_args

        # DISCUSS: do we really need step_args?
        task, options, runner_options = build_task_for(proc, user_options, step_args.args_for_TaskBuilder, task_builder)

        # 1. insert Step into Sequence (append, replace, before, etc.)
        sequence.insert!(task, options[:name], options, step_args)
        # sequence is now an up-to-date representation of our operation's steps.

        # 2. transform sequence to Activity
        alterations = railway_alterations + sequence.to_alterations

        # 3. apply alterations and return the built up activity
        Alterations.new(alterations).(nil) # returns `Activity`.
        # 4. save Activity in operation (on the outside)
      end

      private

      # Returns the {Task} instance to be inserted into the {Circuit}, its options (e.g. :name)
      # and the runner_options.
      def build_task_for(proc, user_options, args_for_task_builder, task_builder)
         macro = proc.is_a?(Array)

        if macro
          task, default_options, runner_options = build_task_for_macro(proc, args_for_task_builder, task_builder)
        else
          # Wrap step code into the actual circuit task.
          task, default_options, runner_options = build_task_for_step(proc, args_for_task_builder, task_builder)
        end

        options = process_options(default_options, user_options)

        return task, options, runner_options
      end

      def build_task_for_step(proc, args_for_task_builder, task_builder)
        proc, default_options = proc, { name: proc }

        task = task_builder.(proc, *args_for_task_builder)

        return task, default_options, {}
      end

      def build_task_for_macro(proc, args_for_task_builder, task_builder)
        proc, default_options, runner_options = *proc

        return proc, default_options, runner_options || {}
      end

      # Normalizes :override and :name options.
      def process_options(default_options, user_options)
        options = default_options.merge(user_options)
        options = options.merge(replace: options[:name]) if options[:override] # :override
        options
      end

      class Alterations < Array# TODO: merge with Wrap::Alterations
        def call(start)
          inject(start) { |circuit, alteration| alteration.(circuit) }
        end
      end
    end # DSL
  end
end
