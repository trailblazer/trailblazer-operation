module Trailblazer
  module Operation::Railway
    # WARNING: The API here is still in a state of flux since we want to provide a simple yet flexible solution.
    # This is code executed at compile-time and can be slow.
    # @note `__sequence__` is a private concept, your custom DSL code should not rely on it.


    # DRAFT
    #  direction: "(output) signal"


    # row.wirings.first[1] #=> [:End, :success]


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

      StepArgs = Struct.new(:args_for_task_builder, :wirings)

      def output_mappings_for_pass(*args)
        {
          :success => [ [:End, :success] ],
          :failure => [ [:End, :success] ]
        }
      end

      def output_mappings_for_fail(*args)
        {
          :success => [ [:End, :failure] ],
          :failure => [ [:End, :failure] ]
        }
      end

      def output_mappings_for_step(*args)
        {
          :success => [ [:End, :success] ],
          :failure => [ [:End, :failure] ]
        }
      end

      # DISCUSS: can we avoid using :outgoing and use connect! for all? problem is that [:End, :success] gets disconnected after the insert.

      def wirings_for_pass(*args)
        [
          [:insert_before!, [:End, :success], incoming: ->(edge) { edge[:type] == :railway }, node: nil, outgoing: [Circuit::Right, type: :railway] ],
          # [:connect!,       node: [:End, :success], edge: [Circuit::Right, type: :railway] ],
        ]
      end

      def args_for_fail(*args)
        StepArgs.new( [Circuit::Left, Circuit::Left],
          [
            [:insert_before!, [:End, :failure], incoming: ->(edge) { edge[:type] == :railway }, node: nil, outgoing: [Circuit::Left, type: :railway] ],
            # [:connect!, node: [:End, :failure], edge: [Circuit::Left, type: :railway] ],
          ]
        )
      end

      # `step` uses the same wirings as `pass`, but also connects the node to the left track.
      def args_for_step(*args)
        StepArgs.new( [Circuit::Right, Circuit::Left],
          wirings_for_pass << [:connect!, source: "fixme!!!" , edge: [Circuit::Left, type: :railway], target: [:End, :failure] ]
        )
      end

      # |-- compile initial act from alterations
      # |-- add step alterations
      def add_step!(type, proc, user_options, task_builder=Operation::Railway::TaskBuilder, task_outputs:raise)
        heritage.record(type, proc, user_options)


        step_proc, options_from_macro, runner_options, outputs_map = *proc
        # now, outputs_map might be nil because a task doesn't have them, yet.


        # build the task.
        task = if options_from_macro.nil?
          options_from_macro = {} # DISCUSS.
          outputs_map     = task_outputs

          build_task_for_step(step_proc, [Circuit::Right, Circuit::Left], task_builder)   # ALWAYS let task builder return two ends. FIXME: remove task builder's configuration and make it dumb.
        else
          outputs_map     = task_outputs if outputs_map.nil? # FIXME: macros must always return their endings.
          step_proc # a macro always returns a Task already.
        end

        # normalize options generically, such as :name, :override, etc.
        options = process_options(options_from_macro, user_options)


        wirings = []
        id      = options[:name] # DISCUSS all this
        debug   = { id: id }

        step_specific_targets = send("output_mappings_for_#{type}") # { :success => [ [:End, :success] ] }
        insert_before_id      = step_specific_targets.values.first.first #=> [:End, :success] # FIXME: this is very implicit and not really transparent.

        #---
        # insert_before! section
        wirings << [:insert_before!, insert_before_id, incoming: ->(edge) { edge[:type] == :railway }, node: [ task, { id: id } ] ]

        #---
        # connect! section
        # this is what the task has
        outputs_map # { Left => { role: :failure }}
        # this is what the operation has


        outputs_map.collect do |signal, options|
          target = step_specific_targets[ options[:role] ].first # DISCUSS: do we need more than one, here?

          wirings <<  [:connect!, source: id, edge: [signal, type: :railway], target: target ] # e.g. "Left --> End.failure"
        end


        wirings = Operation::DSL::TaskWiring.new(wirings, debug)




        sequence = self["__sequence__"]





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

      # Returns the {Task} instance to be inserted into the {Circuit}, its options (e.g. :name)
      # and the runner_options.
      #
      # Steps can use a task builder to wrap the user step into a task.
      # Macros return their low-level circuit task directly.
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

        # return task, default_options, {}
      end

      def build_task_for_macro(proc, args_for_task_builder, task_builder)
        task, default_options, runner_options = *proc

        return task, default_options, runner_options || {}
      end

      # Normalizes :override and :name options.
      def process_options(default_options, user_options)
        options = default_options.merge(user_options)
        options = options.merge(replace: options[:name]) if options[:override] # :override
        options
      end
    end # DSL
  end
end
