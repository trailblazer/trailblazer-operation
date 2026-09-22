require "trailblazer/operation/version"
require "trailblazer/activity/dsl"
require "trailblazer/developer"
# require "trailblazer/invoke"
# require "forwardable"

#
# Developer's docs: https://trailblazer.to/2.1/docs/internals.html#internals-operation
#
module Trailblazer
  # def self.Operation(options)
  #   Class.new(Activity::FastTrack( Activity::Operation.OptionsForState.merge(options) )) do
  #     extend Operation::PublicCall
  #     raise # FIXME: what is the matter with you?
  #   end
  # end

  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, etc.
  #
  # The Trailblazer::Activity::FastTrack topology sits in the trailblazer-activity-dsl gem.
  # Again, the Operation is just a preconfigured frontend plus the Operation.() public interface plus the Result object.
  class Operation < Activity::FastTrack
    # DISCUSS: instead of a #__ method that "acts as a global", let's try it with this directive.
    setting :args_compiler_for_invoke
    setting :args_compiler_for_debugging # DISCUSS: not sure we need that?

    config.args_compiler_for_invoke = Activity::Invoke::Args::Compiler # so far, the most basic.
    config.args_compiler_for_debugging = Circuit::Adds.(
      Activity::Invoke::Args::Compiler,
      # FIXME: i took this from wtf_test, this should be shipped with developer.
      [:my_trace, Circuit::Node[Developer::Trace::Invoke.method(:add_options_for_trace), Circuit::Task::Adapter::LibInterface], :before, :produce_wrap_runtime],
      [:my_wtf, Circuit::Node[Developer::Wtf::Invoke.method(:produce_wtf_node), Circuit::Task::Adapter::LibInterface], :before, :produce_wrap_runtime],
    )

    # NOTE: this is only invoked once, by you, on the very top level.
    #       Nested operations don't have their .call method invoked.
    def self.call(**options, &block)
      lib_ctx = {target_ctx: options}

      lib_ctx, flow_options, signal = Activity::Invoke.(self, lib_ctx, compiler: config.args_compiler_for_invoke,
        extensions: [], # FIXME: who defauls this?
        id: self.inspect, # FIXME: who defauls this?
        )

      return Result.build(signal, lib_ctx.fetch(:target_ctx))
    end

    # require "trailblazer/operation/wtf"
    # extend Wtf                   # Operation.trace
  end
end

require "trailblazer/operation/result"

# Trailblazer::Operation.configure! { {} } # create a default Operation.() with no dynamic args set.

=begin
Trailblazer::Operation.instance_variable_get(:@state).update!(:fields) do |fields|
  # Override Activity's initial taskWrap.
  # This way, an OP is never called using `call`, always via `#strategy_call` (even the top in Invoke).

  # Even though this is much cleaner, "problem" with this approach is that
  # nested OPs won't have {Operation.call} invoked anymore, which breaks some users' tests
  # especially those with expectations on nested OPs being {call}ed.
  fields.merge(
    task_wrap: Trailblazer::Operation::PublicCall::INITIAL_TASK_WRAP  # HERE, we can add other tw steps like dependeny injection.
  )
end
=end
