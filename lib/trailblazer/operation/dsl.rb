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


        # step_proc, options_from_macro, runner_options, task_outputs = *proc
        # now, task_outputs might be nil because a task doesn't have them, yet.


        # build the task.
        #   runner_options #=>{:alteration=>#<Proc:0x00000001dcbb20@test/task_wrap_test.rb:15 (lambda)>}
        task, options_from_macro, runner_options, task_outputs = if proc.is_a?(Array)
          build_task_for_macro( task_builder: task_builder, step: proc, task_outputs: task_outputs )
        else
          build_task_for_step( task_builder: task_builder, step: proc, task_outputs: task_outputs )
        end

        # normalize options generically, such as :name, :override, etc.
        options = process_options( options_from_macro, user_options, name: proc )

        # raise options[:name].inspect

        wirings         = []

        id              = options[:name] # DISCUSS all this
        task_meta_data  = { id: id, created_by: type } # this is where we can add meta-data like "is a subprocess", "boundary events", etc.

        known_targets     = send("output_mappings_for_#{type}",  task, options) #=> { :success => [ [:End, :success] ] }
        insert_before_id  = send("insert_before_id_for_#{type}", task, options) #=> [:End, :success]

        #---
        # insert_before! section
        wirings << [:insert_before!, insert_before_id, incoming: ->(edge) { edge[:type] == :railway }, node: [ task, task_meta_data ] ]

        #---
        # connect! section
        # task_outputs is what the task has
        task_outputs.collect do |signal, options|
          target = known_targets[ options[:role] ]

          # TODO: add more options to edge like role: :success or role: pass_fast.
          # FIXME: don't mark pass_fast with :railway
          wirings <<  [:connect!, source: id, edge: [signal, type: :railway], target: target ] # e.g. "Left --> End.failure"
        end


        wirings = Operation::DSL::TaskWiring.new(wirings, id, task_meta_data)




        sequence = self["__sequence__"]




        puts "~~~"
        # 1. insert Step into Sequence (by respecting append, replace, before, etc.)
        sequence.insert!(wirings, options)
        # sequence is now an up-to-date representation of our operation's steps.

        # FIXME: overwriting @start here sucks.
        @start, self["__graph__"], self["__activity__"] = recompile_activity!( sequence, InitialActivity() )

        {
          start:    @start,
          graph:    self["__graph__"],
          circuit:  self["__activity__"],

          # also return all computed data for this step:
          task:           task,
          options:        options,
          runner_options: runner_options,
          task_outputs:   task_outputs, # we don't need them outside.
        }
      end

      # @api private
      # 1. Processes the step API's options (such as `:override` of `:before`).
      # 2. Uses `Sequence.alter!` to maintain a linear array representation of the circuit's tasks.
      #    This is then transformed into a circuit/Activity. (We could save this step with some graph magic)
      # 3. Returns a new Activity instance.
      #
      # This is called per "step"/task insertion.
      def recompile_activity!(sequence, graph)
        sequence.each do |wirings|
          wirings.(graph)
        end

        end_events = graph.find_all { |node| node.successors.size == 0 } # Find leafs of graph.
          .collect { |n| n[:_wrapped] } # unwrap the actual End event instance from the Node.

        return graph[:_wrapped], graph, Circuit.new(graph.to_h( include_leafs: false ), end_events, {})
      end

      private

      def build_task_for_step(step:raise, task_outputs:raise, task_builder: Operation::Railway::TaskBuilder)
        task = task_builder.(step, Circuit::Right, Circuit::Left)

        [ task, {}, {}, task_outputs ]
      end

      def build_task_for_macro(step:raise, task_outputs:raise, **)
        task, options_from_macro, runner_options, _task_outputs = *step

        # defaultize, DISCUSS whether or not macros should do this.
        _task_outputs  = task_outputs if _task_outputs.nil? # FIXME: macros must always return their endings.
        runner_options = {} if runner_options.nil?

        [ task, options_from_macro, runner_options, _task_outputs ]
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
