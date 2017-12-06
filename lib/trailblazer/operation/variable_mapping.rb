class Trailblazer::Activity
  module Wrap
    # TaskWrap step to compute the incoming {Context} for the wrapped task.
    # This allows renaming, filtering, hiding, of the options passed into the wrapped task.
    #
    # Both Input and Output are typically to be added before and after task_wrap.call_task.
    #
    # @note Assumption: we always have :input _and_ :output, where :input produces a Context and :output decomposes it.
    class Input
      def initialize(filter)
        @filter = Trailblazer::Option(filter)
      end

      # `original_args` are the actual args passed to the wrapped task: [ [options, ..], circuit_options ]
      #
      def call((wrap_ctx, original_args), **circuit_options)
        # let user compute new ctx for the wrapped task.
        input_ctx = apply_filter(*original_args)

        # TODO: make this unnecessary.
        # wrap user's hash in Context if it's not one, already (in case user used options.merge).
        # DISCUSS: should we restrict user to .merge and options.Context?
        input_ctx = Trailblazer.Context({}, input_ctx) unless input_ctx.instance_of?(Trailblazer::Context)

        wrap_ctx = wrap_ctx.merge( vm_original_args: original_args )

        # decompose the original_args since we want to modify them.
        (original_ctx, original_flow_options), original_circuit_options = original_args

        # instead of the original Context, pass on the filtered `input_ctx` in the wrap.
        return Trailblazer::Activity::Right, [ wrap_ctx, [[input_ctx, original_flow_options], original_circuit_options] ]
      end

      private

      def apply_filter((original_ctx, original_flow_options), original_circuit_options)
        @filter.( original_ctx, **original_circuit_options )
      end
    end

    # TaskWrap step to compute the outgoing {Context} from the wrapped task.
    # This allows renaming, filtering, hiding, of the options returned from the wrapped task.
    class Output
      def initialize(filter, strategy=CopyMutableToOriginal)
        @filter   = Trailblazer::Option(filter)
        @strategy = strategy
      end

      # Runs the user filter and replaces the ctx in `wrap_ctx[:result_args]` with the filtered one.
      def call((wrap_ctx, original_args), **circuit_options)
        (original_ctx, original_flow_options), original_circuit_options = original_args

        returned_ctx, _ = wrap_ctx[:result_args] # this is the context returned from `call`ing the task.

        # returned_ctx is the Context object from the nested operation. In <=2.1, this might be a completely different one
        # than "ours" we created in Input. We now need to compile a list of all added values. This is time-intensive and should
        # be optimized by removing as many Context creations as possible (e.g. the one adding self[] stuff in Operation.__call__).
        _, mutable_data = returned_ctx.decompose # FIXME: this is a weak assumption. What if the task returns a deeply nested Context?

        # let user compute the output.
        output = apply_filter(mutable_data, original_flow_options, original_circuit_options)

        original_ctx = wrap_ctx[:vm_original_args][0][0]

        new_ctx = @strategy.( original_ctx, output ) # here, we compute the "new" options {Context}.

        wrap_ctx = wrap_ctx.merge( result_args: [new_ctx, original_flow_options] )

        # and then pass on the "new" context.
        return Trailblazer::Activity::Right, [ wrap_ctx, original_args ]
      end

      private

      # @note API not stable
      def apply_filter(mutable_data, original_flow_options, original_circuit_options)
        @filter.(mutable_data, **original_circuit_options)
      end

      # "merge" Strategy
      class CopyMutableToOriginal
        # @param original Context
        # @param options  Context The object returned from a (nested) {Activity}.
        def self.call(original, mutable)
          mutable.each { |k,v| original[k] = v }

          original
        end
      end
    end
  end # Wrap
end
