module Trailblazer
  module Operation::Railway
    # WARNING: The API here is still in a state of flux since we want to provide a simple yet flexible solution.
    # This is code executed at compile-time and can be slow.
    # @note `__sequence__` is a private concept, your custom DSL code should not rely on it.


    # DRAFT
    #  direction: "(output) signal"

    module DSL
      def pass(proc, options={}); add_step!(:pass, proc, options); end
      def fail(proc, options={}); add_step!(:fail, proc, options); end
      def step(proc, options={}); add_step!(:step, proc, options); end
      alias_method :success, :pass
      alias_method :failure, :fail

      private
      # InsertBeforeArgs = [ end_node, node: [ task, id: options[:name] ], outgoing: Circuit::Right, incoming: ->(edge) { edge.type == :railway } ]
      # ConnectArgs = [ source: [:bla, :id], node: [ task, id: options[:name], type: :event ], edge: [ FailFast, type: :railway ] ]


      StepArgs = Struct.new(:args_for_task_builder, :wirings)

# macro says: [ nested[:End, :default],                  target ]
#              concrete output signal (macro knows it) => [:End, :right], [:End, ]
      # Override these if you want to extend how tasks are built.
      def args_for_pass(*args)
        StepArgs.new( [Circuit::Right, Circuit::Right], wirings_for_pass(*args) )
      end

      # DISCUSS: can we avoid using :outgoing and use connect! for all? problem is that [:End, :success] gets disconnected after the insert.

      def wirings_for_pass(*args)
        [
          [:insert_before!, [:End, :success], incoming: ->(edge) { edge[:type] == :railway }, node: nil, outgoing: [Circuit::Right, type: :railway] ],
          # [:connect!, node: [:End, :success], edge: [Circuit::Right, type: :railway] ],
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
          wirings_for_pass << [:connect!, node: [:End, :failure], edge: [Circuit::Left,  type: :railway] ]
        )
      end

      # |-- compile initial act from alterations
      # |-- add step alterations
      def add_step!(type, proc, user_options, task_builder=Operation::Railway::TaskBuilder)
        heritage.record(type, proc, user_options)

        # compile the default arguments specific to step/fail/pass.
        step_args = send("args_for_#{type}", proc, user_options) # call args_for_pass/args_for_fail/args_for_step.




        # # compile the step's options like :name.
        # proc, user_options = *step_args.original_args

        # DISCUSS: do we really need step_args?
          # this is where we retrieve config. now insert! needs to get configured properly
        task, options, runner_options = build_task_for(proc, user_options, step_args.args_for_task_builder, task_builder)

        # step_cfg = step_args.to_h

        # # now, map the connections to the existing step_args.connections
        # step_cfg[:connections] = runner_options[:connections] unless runner_options[:connections].nil?
        # # FIXME: rename runner_options to config or something.
        # puts "@@@@@ #{step_cfg[:connections].inspect}"
        wirings = step_args.wirings

        sequence = self["__sequence__"]





        # 1. insert Step into Sequence (by respecting append, replace, before, etc.)
        sequence.insert!(task, options, wirings)
        # sequence is now an up-to-date representation of our operation's steps.



        # TODO: how do we handle basic wirings?
        graph = InitialActivity()


        # re-compile the activity with every DSL call.
        self["__activity__"] = recompile_activity(graph, sequence)
      end

      # @api private
      # 1. Processes the step API's options (such as `:override` of `:before`).
      # 2. Uses `Sequence.alter!` to maintain a linear array representation of the circuit's tasks.
      #    This is then transformed into a circuit/Activity. (We could save this step with some graph magic)
      # 3. Returns a new Activity instance.
      #
      # This is called per "step"/task insertion.
      def recompile_activity(graph, sequence)


        sequence.each do |row|
          task    = row.task
          options = { id: row.name }

          row.wirings.each do |wiring|
            # DISCUSS: this could also be a lambda, but sucks for development.
            wiring.last[:node] = [ task, options ] if wiring.last[:node].nil? # FIXME: this is only needed for connect!

 # puts wiring.inspect

            graph.send *wiring
# puts graph.find_all { |n| puts n.inspect; puts }

          end
        end

# require "pp"
#         pp graph

        # Find leafs of graph.
        end_events = graph.find_all { |node| node.successors.size == 0 }


 puts
        puts
        require "pp"
        pp graph


        return Circuit.new(graph.to_h, end_events, { id: self.class.to_s,  })



        # 2. transform sequence to Activity
        alterations = railway_alterations + sequence.to_alterations

        # 3. apply alterations and return the built up activity
        Alterations.new(alterations).(nil) # returns `Activity`.
        # 4. save Activity in operation (on the outside)
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

        return task, default_options, {}
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
