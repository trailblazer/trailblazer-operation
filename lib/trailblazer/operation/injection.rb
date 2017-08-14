module Trailblazer
  module Operation::TaskWrap
    # The behavior in this module used to be part of {https://github.com/trailblazer/trailblazer-operation/blob/31e122f1787b72835d52a8a127c718ab49ee51e4/lib/trailblazer/operation/pipetree.rb#L129 Pipetree::Step}.
    module Injection
      # Returns an Alteration proc that, when applied, inserts the {ReverseMergeDefaults} task
      # before the {Wrap::Call} task. This is meant for macros and steps that accept a dependency
      # injection but need a default parameter to be set if not injected.
      # @returns Alteration
      def self.SetDefaults(default_dependencies)
        [
          [ :insert_before!, "task_wrap.call_task", node: [ ReverseMergeDefaults( default_dependencies ), id: "ReverseMergeDefaults#{default_dependencies}" ], incoming: Proc.new{ true }, outgoing: [ Circuit::Right, {} ] ]
        ]
      end

      # @api private
      # @returns Task
      # @param Hash list of key/value that should be set if not already assigned/set before (or injected from the outside).
      def self.ReverseMergeDefaults(default_dependencies)
        ->(direction, options, flow_options, *args) do
          default_dependencies.each { |k, v| options[k] ||= v }

          [ direction, options, flow_options, *args ]
        end
      end
    end

    # TODO: writes hard to options.
    # TODO: add Context and Uninject.
  end
end
