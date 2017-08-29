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
      def pass(proc, options={}); add_step_or_task_from_railway!(proc, options, type: :pass ); end
      def fail(proc, options={}); add_step_or_task_from_railway!(proc, options, type: :fail ); end
      def step(proc, options={}); add_step_or_task_from_railway!(proc, options, type: :step ); end
      alias_method :success, :pass
      alias_method :failure, :fail

      private

      def connect_to_for_pass(options)
        {
          :success => "End.success",
          :failure => "End.success"
        }
      end

      def connect_to_for_fail(options)
        {
          :success => "End.failure",
          :failure => "End.failure"
        }
      end

      def connect_to_for_step(options)
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
      # It provides sensible defaults such as :default_task_outputs or :insert_before.
      def add_step_or_task_from_railway!(proc, user_options, type:raise)
        defaults = {
          type:                 type,
          task_builder:         TaskBuilder,
          connect_to:           send("connect_to_for_#{type}", user_options),
          insert_before:        send("insert_before_for_#{type}", user_options),
          default_task_outputs: default_task_outputs(user_options),
          alteration:           Insert,
        }

        _element( proc, user_options, defaults )
      end

      # Merges user_options over the defaults, allowing to inject different configuration and graph behavior via the step/pass/insert DSL.
      def _element(proc, user_options, **defaults)
        add_step_or_task!(
          proc,
          user_options,
          defaults.merge( user_options ) # merge DEFAULT options with USER options.
        )
      end

      # { ..., runner_options: {}, } = add_step_or_task!

      # DECOUPLED FROM any "local" config, except for __activity__, etc.
      # @param user_options Hash this is only used for non-alteration options, such as :before.
      def add_step_or_task!(proc, user_options, alteration:raise, type:nil, task_builder:raise, **user_alteration_options)
        heritage.record(type, proc, user_options) # FIXME.

        id, macro_alteration_options, seq_options = Normalize.(proc, user_options, task_builder: task_builder, type: type)

        # alteration == Insert, Attach, Connect, etc.
        # merge the MACRO options with the USER options
        wirings = alteration.(id, macro_alteration_options.merge( user_alteration_options ) )

        add_element!( wirings, seq_options.merge(id: id) )

        # RETURN WHAT WE COMPUTED HERE. not sure about the API, yet.
        macro_alteration_options
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

      # This is called per "step"/task insertion.
      # @private
      def recompile_activity(wirings)
        Trailblazer::Activity.from_wirings(wirings)
      end

      # Receives the user's step `proc` and the user options. Computes id, seq options, the actual task to add to the graph, etc.
      # This function does not care about any alteration-specific user options, such as :insert_before.
      class Normalize
        def self.call(proc, user_options, task_builder:raise, type:raise)
          # these are the macro's (or steps) configurations, like :outputs or :id.
          macro_alteration_options = normalize_macro_options(proc, task_builder)

          # this id computation is specific to the step/pass/fail API and not add_task!'s job.
          node_data, id = normalize_node_data( macro_alteration_options[:node_data], user_options, type )
          seq_options   = normalize_sequence_options(id, user_options)

          macro_alteration_options = macro_alteration_options.merge( node_data: node_data ) # TODO: DEEP MERGE node_data in case there's data from user

          return id, macro_alteration_options, seq_options
        end

        private

        def self.normalize_macro_options(proc, task_builder)
          if proc.is_a?(::Hash) # macro.
            proc
          else # user step.
            {
              task:      task_builder.(proc, Circuit::Right, Circuit::Left),
              node_data: { id: proc }
            }
          # TODO: allow every step to have runner_options, etc
          end
        end

        def self.normalize_node_data(node_data, user_options, created_by)
          id = user_options[:id] || user_options[:name] || node_data[:id]

          return node_data.merge(
            id:         id,
            created_by: created_by # this is where we can add meta-data like "is a subprocess", "boundary events", etc.
          ), id # TODO: remove :name
        end

        # Normalizes :override.
        # DSL::step/pass specific.
        def self.normalize_sequence_options(id, override:nil, before:nil, after:nil, replace:nil, delete:nil, **user_options)
          override ? { replace: id }.freeze : { before: before, after: after, replace: replace, delete: delete }.freeze
        end
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
