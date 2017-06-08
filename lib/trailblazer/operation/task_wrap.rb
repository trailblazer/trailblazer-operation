module Trailblazer
  module Operation::Railway
    module TaskWrap
      def self.included(includer)
        includer.extend ClassMethods # ::call, ::inititalize_pipetree!
        includer.extend DSL

        includer.initialize_task_wraps!
      end

      module ClassMethods
        def initialize_task_wraps!
          heritage.record :initialize_task_wraps!

          self["__task_wraps__"] = {}
        end
      end

      module DSL
        def build_task_for(*args)
          super.tap do |task, options, runner_options| # Railway::DSL::build_task_for
            alteration = runner_options[:alteration] || ->(activity) { activity }

            self["__task_wraps__"][task] = alteration.( Circuit::Activity::Wrapped::Activity )
          end
        end
      end
    end # TaskWrap
  end
end
