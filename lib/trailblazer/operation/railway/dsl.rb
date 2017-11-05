module Trailblazer
  module Operation::Railway
    # WARNING: The API here is still in a state of flux since we want to provide a simple yet flexible solution.
    # This is code executed at compile-time and can be slow.
    # @note `__sequence__` is a private concept, your custom DSL code should not rely on it.


    # DRAFT
    #  direction: "(output) signal"
    #

    # options merging
    #  1. Defaults_from_DSL.merge user_options
    #  2. macro_options.merge ( 1. )

    # document ## Outputs
    #   task/acti has outputs, role_to_target says which task output goes to what next task in the composing acti.

    module DSL
      def pass(proc, options={}); add_step_or_task_from_railway!(proc, options, type: :pass ); end
      def fail(proc, options={}); add_step_or_task_from_railway!(proc, options, type: :fail ); end
      def step(proc, options={}); add_step_or_task_from_railway!(proc, options, type: :step ); end
      alias_method :success, :pass
      alias_method :failure, :fail

      private

      def Output(signal, color)
        Trailblazer::Activity::Schema::Output.new(signal, color)
      end

      def seqargs_for_step(options)
                      # Output semantic => magnetic color/polarization
        [ [:success], { success: :success, failure: :failure } ]
      end

      def seqargs_for_pass(options)
        [ [:success], { success: :success, failure: :success } ]
      end

      # [:red], { success: :red, failure: :red }
      def seqargs_for_fail(options)
        [ [:failure], { success: :failure, failure: :failure } ]
      end

      # An unaware step task usually has two outputs, one end event for success and one for failure.
      # Note that macros have to define their outputs when inserted and don't need a default config.
      def default_task_outputs(options)
        # generic Outputs data structure.
        { Circuit::Right => { role: :success }, Circuit::Left => { role: :failure }}
      end

      # Normalizations specific to the Operation's standard DSL, as pass/fail/step.
      # It provides sensible defaults such as :default_task_outputs or :insert_before.
      def add_step_or_task_from_railway!(proc, user_options, type:raise)
        defaults = {
          type:                 type,
          task_builder:         TaskBuilder,
          # connect_to:           send("connect_to_for_#{type}", user_options),
          # insert_before:        send("insert_before_for_#{type}", user_options),

          railway_step: send("seqargs_for_#{type}", user_options),


          outputs:              default_task_outputs(user_options),
        }

        _element( proc, user_options, defaults ) # DSL::Magnetic::Processor
      end


      # { task: bla, outputs: bla } # macro
      # ActivityInterface # activity
      # lambda # step

      # step Validate, no_key_err: "End.fail_fast"

      module Magnetic
        module Processor
          def self.call(id, options)
            magnetic_to, connect_to = options[:railway_step]

            outputs = role_to_plus_pole( options[:outputs], connect_to )

            # raise outputs.inspect
            [
              [ magnetic_to, options[:task], outputs ]
            ]
          end

          def self.role_to_plus_pole(outputs, connect_to)
            outputs.collect do |signal, role:raise|
              color = connect_to[ role ] or raise "Couldn't map output role #{role.inspect} for #{connect_to.inspect}"

              Activity::Schema::Output.new(signal, color)
            end
          end
        end
      end


      # DECOUPLED FROM any "local" config, except for __activity__, etc.
      # @param user_options Hash this is only used for non-alteration options, such as :before.
      # @return { ..., runner_options: {}, }
      def _element(proc, user_options, type:nil, task_builder:raise, **defaults)
        heritage.record(type, proc, user_options) # FIXME.

        id, macro_alteration_options, seq_options = Normalize.(proc, user_options, task_builder: task_builder, type: type)

        # TODO: test how macros can now use defaults, too.
        defaults          = ::Declarative::Variables.merge(defaults, macro_alteration_options)
        effective_options = ::Declarative::Variables.merge(defaults, user_options)

        # alteration == Insert, Attach, Connect, etc.
        # wirings = alteration.(id, effective_options )

        sequence_adds = Magnetic::Processor.( id, effective_options )


        add_element!( sequence_adds, seq_options.merge(id: id) )

        # RETURN WHAT WE COMPUTED HERE. not sure about the API, yet.
        effective_options
      end

      # This method is generic for any kind of insertion/attach/connect.
      # params wirings Array
      # params sequence_options Hash containing where to insert in the Sequence (:before, :replace, etc.)
      # semi-public
      def add_element!(sequence_adds, id:raise, **sequence_options)
        sequence_adds.each do |instruction|
          self["__sequence__"].add(id, instruction)
        end


        self["__activity__"] = recompile_activity( self["__sequence__"] )
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
              node_data: { id: proc },
              # outputs: proc.outputs,
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
    end # DSL
  end
end
