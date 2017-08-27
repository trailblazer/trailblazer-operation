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
      def pass(proc, options={}); add_step_or_task_from_railway!(proc, options, type: :pass, default_task_outputs: default_task_outputs(options) ); end
      def fail(proc, options={}); add_step_or_task_from_railway!(proc, options, type: :fail, default_task_outputs: default_task_outputs(options) ); end
      def step(proc, options={}); add_step_or_task_from_railway!(proc, options, type: :step, default_task_outputs: default_task_outputs(options) ); end
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

      # Normalizations specific to the Operation's standard DSL, as pass/fail/step.
      def add_step_or_task_from_railway!(proc, user_options, type:raise, task_builder:TaskBuilder, connect_to:send("role_to_target_for_#{type}", user_options), insert_before:send("insert_before_for_#{type}", user_options), **opts)
        add_step_or_task!( proc, user_options, opts.merge(connect_to: connect_to, insert_before: insert_before, type:type, task_builder:task_builder) )
      end

      # { ..., runner_options: {}, } = add_step_or_task!

      # DECOUPLED FROM any "local" config, except for __activity__, etc.
      def add_step_or_task!(proc, user_options, type:nil, task_builder:TaskBuilder, **user_alteration_options)
        heritage.record(type, proc, user_options) # FIXME.

        # these are the macro's (or steps) configurations, like :outputs or :id.
        macro_alteration_options =
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
        node_data, id = normalize_node_data( macro_alteration_options[:node_data], user_options, type )
        seq_options   = normalize_sequence_options(id, user_options)

        wirings = insert!(id, macro_alteration_options.merge( user_alteration_options ).merge( node_data: node_data ) ) # TODO: DEEP MERGE node_data in case there's data from user

        add_element!( wirings, seq_options.merge(id: id) )

        # RETURN WHAT WE COMPUTED HERE. not sure about the API, yet.
        macro_alteration_options
      end

      def insert!(id, **insertion_options)
        insertion_options =
          { # defaults
            outputs:       insertion_options[:default_task_outputs],
          }.merge(insertion_options)

        options, _ = insertion_args_for( insertion_options )

        wirings = insertion_wirings_for( options ) # TODO: this means macro could say where to insert?
      end


      # This method is generic for any kind of insertion/attach/connect.
      # params wirings Array
      # params sequence_options Hash containing where to insert in the Sequence (:before, :replace, etc.)
      # semi-public
      def add_element!(wirings, id:raise, **sequence_options)
        self["__activity__"] = recompile_activity_for_wirings!(id, wirings, sequence_options)
      end

      # @private
      def recompile_activity_for_wirings!(id, wirings, sequence_options)
        sequence = self["__sequence__"]

        # Insert wirings as one element into {Sequence} while respecting :append, :replace, before, etc.
        sequence.insert!(id, wirings, sequence_options) # The sequence is now an up-to-date representation of our operation's steps.

        # This op's graph are the initial wirings (different ends, etc) + the steps we added.
        activity = recompile_activity( self["__wirings__"] + sequence.to_a )
      end

      def insertion_args_for(task:raise, node_data:raise, insert_before:raise, outputs:raise, connect_to:raise, **passthrough)
        # something like *** would be cool
        return {
          task:          task,
          node_data:     node_data,
          insert_before: insert_before,
          outputs:       outputs,
          connect_to:    connect_to
        }.freeze
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

        wirings # embraces all alterations for one "step".
      end

      def normalize_node_data(node_data, user_options, created_by)
        id = user_options[:id] || user_options[:name] || node_data[:id]

        return node_data.merge(
          id:         id,
          created_by: created_by # this is where we can add meta-data like "is a subprocess", "boundary events", etc.
        ), id # TODO: remove :name
      end

      # Normalizes :override.
      # DSL::step/pass specific.
      def normalize_sequence_options(id, override:nil, before:nil, after:nil, replace:nil, delete:nil, **user_options)
        override ? { replace: id }.freeze : { before: before, after: after, replace: replace, delete: delete }.freeze
      end

      # This is called per "step"/task insertion.
      # @private
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
