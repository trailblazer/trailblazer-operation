module Trailblazer
  module Operation::Railway
    # WARNING: The API here is still in a state of flux since we want to provide a simple yet flexible solution.
    # This is code executed at compile-time and can be slow.
    # @note `__sequence__` is a private concept, your custom DSL code should not rely on it.


    # DRAFT
    #  direction: "(output) signal"

    # document ## Outputs
    #   task/acti has outputs, role_to_target says which task output goes to what next task in the composing acti.

    module DSL
      def pass(proc, options={}); add_step_or_task!(proc, options, type: :pass, default_task_outputs: default_task_outputs(options) ); end
      def fail(proc, options={}); add_step_or_task!(proc, options, type: :fail, default_task_outputs: default_task_outputs(options) ); end
      def step(proc, options={}); add_step_or_task!(proc, options, type: :step, default_task_outputs: default_task_outputs(options) ); end
      alias_method :success, :pass
      alias_method :failure, :fail

      private

      def role_to_target_for_pass(options)
        {
          :success => "End.success",
          :failure => "End.success"
        }
      end

      def role_to_target_for_fail(options)
        {
          :success => "End.failure",
          :failure => "End.failure"
        }
      end

      def role_to_target_for_step(options)
        {
          :success => "End.success",
          :failure => "End.failure"
        }
      end

      def insert_before_for_pass(options)
        "End.success"
      end

      def insert_before_for_fail(options)
        "End.failure"
      end

      def insert_before_for_step(options)
        "End.success"
      end

      # An unaware step task usually has two outputs, one end event for success and one for failure.
      # Note that macros have to define their outputs when inserted and don't need a default config.
      def default_task_outputs(options)
        { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }}
      end

      # insert_before: "End.success",
      # outputs:       { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure } }, # any outputs and their polarization, generic.
      # mappings:      { success: "End.success", failure: "End.myend" } # where do my task's outputs go?
      # always adds task on a track edge.
      # @return ElementWiring
      def insertion_wirings_for(task: nil, insert_before:raise, outputs:{}, connect_to:{}, node_data:raise)
        raise "missing node_data: { id: .. }" if node_data[:id].nil?

        wirings = []

        wirings << [:insert_before!, insert_before, incoming: ->(edge) { edge[:type] == :railway }, node: [ task, node_data ] ]

        # FIXME: don't mark pass_fast with :railway
        raise "bla no outputs remove me at some point " unless outputs.any?
        wirings += Wirings.task_outputs_to(outputs, connect_to, node_data[:id], type: :railway) # connect! for task outputs

        ElementWiring.new(wirings, node_data) # embraces all alterations for one "step".
      end

      def element(*)

      end

      # Normalizations specific to the Operation's standard DSL, as pass/fail/step.
      def add_step_or_task!(proc, user_options, type:nil, task_builder:TaskBuilder, **opts)
        heritage.record(type, proc, user_options)

        insertion_options =
          if proc.is_a?(::Hash) # macro.
            proc
          else # user step.
            {
              task:      task_builder.(proc, Circuit::Right, Circuit::Left),
              node_data: { id: proc }
            }
          # TODO: allow every step to have runner_options, etc
          end

          # this id computation is specific to the step/pass/fail API and not add_task!'s job.
        node_data, id = normalize_node_data( insertion_options[:node_data], user_options, type )

        add_task!( insertion_options.merge(node_data: node_data), opts.merge( id: id, type: type, user_options: user_options ) )
      end

      # NOTE: here, we don't care if it was a step, macro or whatever else.
      def add_task!(insertion_options, default_task_outputs:raise, user_options:raise, type:raise, id:raise)
        role_to_target = send("role_to_target_for_#{type}", user_options) #=> { :success => [ "End.success" ] }
        insert_before  = send("insert_before_for_#{type}", user_options) #=> "End.success"


        options, passthrough = insertion_args_for(
          { # defaults
            outputs:       default_task_outputs,
            insert_before: insert_before,
            connect_to:    role_to_target,
          }.
            merge(insertion_options) # actual user/macro-provided options
        )

        wirings = insertion_wirings_for( options ) # TODO: this means macro could say where to insert?

        self["__activity__"] = recompile_activity_for_wirings!(wirings, id, user_options) # options is :before,:after etc for Seq.insert!

        {
          activity:  self["__activity__"],
          options:   user_options,
        }.merge(passthrough).merge(options)
      end

      ElementWiring = Struct.new(:instructions, :data)

      def insertion_args_for(task:raise, node_data:raise, insert_before:raise, outputs:raise, connect_to:raise, **passthrough)
        # something like *** would be cool
        return {
          task:          task,
          node_data:     node_data,
          insert_before: insert_before,
          outputs:       outputs,
          connect_to:    connect_to
        }.freeze, passthrough
      end


      def normalize_node_data(node_data, user_options, created_by)
        id = user_options[:id] || user_options[:name] || node_data[:id]

        return node_data.merge(
          id:         id,
          created_by: created_by # this is where we can add meta-data like "is a subprocess", "boundary events", etc.
        ), id # TODO: remove :name
      end

      # Normalizes :override and :name options.
      def normalize_sequence_options(id, override:nil, **options)
        # options = macro_options.merge(user_options)
        options = options.merge( replace: id ) if override # :override
        options
      end

      # @private
      def recompile_activity_for_wirings!(wirings, id, user_options)
        seq_options = normalize_sequence_options(id, user_options)

        sequence = self["__sequence__"]

        # Insert {Step} into {Sequence} while respecting :append, :replace, before, etc.
        sequence.insert!(wirings, seq_options) # The sequence is now an up-to-date representation of our operation's steps.

        # This op's graph are the initial wirings (different ends, etc) + the steps we added.
        activity = recompile_activity( self["__wirings__"] + sequence.to_a )
      end

      # @private
      # 1. Processes the step API's options (such as `:override` of `:before`).
      # 2. Uses `Sequence.alter!` to maintain a linear array representation of the circuit's tasks.
      #    This is then transformed into a circuit/Activity. (We could save this step with some graph magic)
      # 3. Returns a new Activity instance.
      #
      # This is called per "step"/task insertion.
      def recompile_activity(wirings)
        Trailblazer::Activity.from_wirings(wirings)
      end

      private

      # @private
      class Wirings # TODO: move to acti.
      #- connect! statements for outputs.
      # @param known_targets Hash {  }
        def self.task_outputs_to(task_outputs, known_targets, id, edge_options)
          # task_outputs is what the task has
          # known_targets are ends this activity/operation provides.
          task_outputs.collect do |signal, role:raise|
            target = known_targets[ role ]
            # TODO: add more options to edge like role: :success or role: pass_fast.

            [:connect!, source: id, edge: [signal, edge_options], target: target ] # e.g. "Left --> End.failure"
          end
        end
      end # Wiring
    end # DSL
  end
end
