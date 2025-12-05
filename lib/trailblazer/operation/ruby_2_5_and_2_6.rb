module Trailblazer
  class Operation
    module Ruby2_5_and_2_6
      module PublicCall
        def call(options = {}, flow_options = nil, circuit_options = {}, **kwargs, &block)
          if flow_options.nil? # public call.
            return super
          else
            circuit_options = kwargs # "misunderstanding" in Ruby < 2.7.
            return strategy_call(options, flow_options, circuit_options)
          end
        end
      end
    end
  end
end

Trailblazer::Operation.singleton_class.prepend(Trailblazer::Operation::Ruby2_5_and_2_6::PublicCall)
