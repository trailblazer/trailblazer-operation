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

      # Builds a custom end event.
      def End(name)
        Class.new(Circuit::End).new(name)
      end

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

          # compute (for the user_options passed in) the magnetic_to, and the connect_to tuples.
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
          def self.call(id, railway_step:raise, **options)
            magnetic_to, connect_to = railway_step

            outputs = role_to_plus_pole( options[:outputs], connect_to )

            [
              [ id, [ magnetic_to, options[:task], outputs ] ]
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


        id, macro_alteration_options, seq_options, dsl_options = Normalize.(proc, user_options, task_builder: task_builder, type: type)

        pp dsl_options

        # TODO: test how macros can now use defaults, too.
        defaults          = ::Declarative::Variables.merge(defaults, macro_alteration_options)
        effective_options = ::Declarative::Variables.merge(defaults, user_options)

        adds = dsl_options.collect do |key, value|
          if (signal, cfg = effective_options[:outputs].find { |signal, role:raise| key == role }) # find out if a DSL argument is an output role...
            if value.kind_of?(Circuit::End)
              [ value.instance_variable_get(:@name), [ [cfg[:role]], value, [] ], group: :end ] # add the new End with magnetic_to the railway step's particular output.


              [  ]
              else
                raise
            end
            # raise value.inspect
            # raise cfg.inspect

          end
        end
        pp adds

        # FIXME: this is of course experimental.
        @__debug ||= {}
        @__debug[id] = effective_options[:node_data]

        sequence_adds = Magnetic::Processor.( id, effective_options )

        add_element!( sequence_adds, seq_options )

        # RETURN WHAT WE COMPUTED HERE. not sure about the API, yet.
        effective_options
      end

      # This method is generic for any kind of insertion/attach/connect.
      # params wirings Array
      # params sequence_options Hash containing where to insert in the Sequence (:before, :replace, etc.)
      # semi-public
      def add_element!(sequence_adds, **sequence_options)
        sequence_adds.each do |instruction|
          self["__sequence__"].add(*instruction, sequence_options)
        end


        self["__activity__"] = recompile_activity( self["__sequence__"] )
      end

      # Receives the user's step `proc` and the user options. Computes id, seq options, the actual task to add to the graph, etc.
      class Normalize
        def self.call(proc, user_options, task_builder:raise, type:raise)
          # these are the macro's (or steps) configurations, like :outputs or :id.
          macro_alteration_options = normalize_macro_options(proc, task_builder)

          # this id computation is specific to the step/pass/fail API and not add_task!'s job.
          node_data, id            = normalize_node_data( macro_alteration_options[:node_data], user_options, type )
          seq_options, dsl_options = normalize_sequence_options(id, user_options)

          macro_alteration_options = macro_alteration_options.merge( node_data: node_data ) # TODO: DEEP MERGE node_data in case there's data from user

          return id, macro_alteration_options, seq_options, dsl_options
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
        def self.normalize_sequence_options(id, override:nil, before:nil, after:nil, replace:nil, delete:nil, **user_dsl_options)
          seq_options = override ? { replace: id }.freeze : { before: before, after: after, replace: replace, delete: delete }.freeze

          return seq_options, user_dsl_options
        end
      end
    end # DSL
  end
end
