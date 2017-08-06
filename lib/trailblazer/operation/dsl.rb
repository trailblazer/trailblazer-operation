module Trailblazer
  module Operation::Railway
    # WARNING: The API here is still in a state of flux since we want to provide a simple yet flexible solution.
    # This is code executed at compile-time and can be slow.
    # @note `__sequence__` is a private concept, your custom DSL code should not rely on it.


    # DRAFT
    #  direction: "(output) signal"

    module DSL
      # An unaware step task usually has two outputs, one end event for success and one for failure.
      # Note that macros have to define their outputs when inserted and don't need a default config.
      DEFAULT_TASK_OUTPUTS = { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }}

      def pass(proc, options={}); add_step!(:pass, proc, options, task_outputs: DEFAULT_TASK_OUTPUTS ); end
      def fail(proc, options={}); add_step!(:fail, proc, options, task_outputs: DEFAULT_TASK_OUTPUTS ); end
      def step(proc, options={}); add_step!(:step, proc, options, task_outputs: DEFAULT_TASK_OUTPUTS ); end
      alias_method :success, :pass
      alias_method :failure, :fail

      private

      def output_mappings_for_pass(task, options)
        {
          :success => [:End, :success],
          :failure => [:End, :success]
        }
      end

      def output_mappings_for_fail(task, options)
        {
          :success => [:End, :failure],
          :failure => [:End, :failure]
        }
      end

      def output_mappings_for_step(task, options)
        {
          :success => [:End, :success],
          :failure => [:End, :failure]
        }
      end

      def insert_before_id_for_pass(task, options)
        [:End, :success]
      end

      def insert_before_id_for_fail(task, options)
        [:End, :failure]
      end

      def insert_before_id_for_step(task, options)
        [:End, :success]
      end

      # |-- compile initial act from alterations
      # |-- add step alterations
      def add_step!(type, proc, user_options, task_builder=Operation::Railway::TaskBuilder, task_outputs:raise)
        heritage.record(type, proc, user_options)


        step_proc, options_from_macro, runner_options, outputs_map = *proc
        # now, outputs_map might be nil because a task doesn't have them, yet.


        # build the task.
        task, options = if options_from_macro.nil?
          options_from_macro = {} # DISCUSS.
          outputs_map     = task_outputs

          build_task_for_step(step_proc, [Circuit::Right, Circuit::Left], task_builder)   # ALWAYS let task builder return two ends. FIXME: remove task builder's configuration and make it dumb.
        else
          outputs_map     = task_outputs if outputs_map.nil? # FIXME: macros must always return their endings.
          step_proc # a macro always returns a Task already.
        end

        # normalize options generically, such as :name, :override, etc.
        options = process_options(options_from_macro, user_options, name: proc)

        # raise options[:name].inspect

        wirings = []
        id      = options[:name] # DISCUSS all this
        debug   = { id: id }

        step_specific_targets = send("output_mappings_for_#{type}",  task, options) #=> { :success => [ [:End, :success] ] }
        insert_before_id      = send("insert_before_id_for_#{type}", task, options) #=> [:End, :success]

        #---
        # insert_before! section
        wirings << [:insert_before!, insert_before_id, incoming: ->(edge) { edge[:type] == :railway }, node: [ task, { id: id } ] ]

        #---
        # connect! section
        # this is what the task has
        outputs_map # { Left => { role: :failure }}


        outputs_map.collect do |signal, options|
          target = step_specific_targets[ options[:role] ]

          # TODO: add more options to edge like role: :success or role: pass_fast.
          wirings <<  [:connect!, source: id, edge: [signal, type: :railway], target: target ] # e.g. "Left --> End.failure"
        end


        wirings = Operation::DSL::TaskWiring.new(wirings, debug)




        sequence = self["__sequence__"]




        puts "~~~"
        # 1. insert Step into Sequence (by respecting append, replace, before, etc.)
        sequence.insert!(task, options, wirings)
        # sequence is now an up-to-date representation of our operation's steps.

        self["__activity__"] = recompile_activity!(sequence)
      end

        # TODO: how do we handle basic wirings?
        # DISCUSS:
        # called with every DSL call and at init. re-compile the activity with every DSL call.
      def recompile_activity!(sequence, graph=InitialActivity())
        recompile_activity_for(graph, sequence)
      end

      # @api private
      # 1. Processes the step API's options (such as `:override` of `:before`).
      # 2. Uses `Sequence.alter!` to maintain a linear array representation of the circuit's tasks.
      #    This is then transformed into a circuit/Activity. (We could save this step with some graph magic)
      # 3. Returns a new Activity instance.
      #
      # This is called per "step"/task insertion.
      def recompile_activity_for(graph, sequence)
        sequence.each do |row|
          task    = row.task
          options = { id: row.name }

          row.wirings.(graph)
        end

        end_events = graph.find_all { |node| node.successors.size == 0 } # Find leafs of graph.
          .collect { |n| n[:_wrapped] } # unwrap the actual End event instance from the Node.

        Circuit.new(graph.to_h, end_events, { id: self.class.to_s,  })
      end

      private

      def build_task_for_step(proc, args_for_task_builder, task_builder)
        task = task_builder.(proc, *args_for_task_builder)
      end

      # Normalizes :override and :name options.
      def process_options(macro_options, user_options, default_options)
        options = macro_options.merge(user_options)
        options = default_options.merge(options)
        options = options.merge(replace: options[:name]) if options[:override] # :override
        options
      end
    end # DSL
  end
end
