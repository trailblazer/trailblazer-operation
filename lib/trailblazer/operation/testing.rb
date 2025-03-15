module Trailblazer
  class Operation
    module Testing
      module Assertions
        # TODO: test me!
        def assert_call(operation, terminus: :success, seq: "[]", expected_ctx_variables: {}, **ctx_variables)
          result = operation.(seq: [], **ctx_variables)

          signal = result.terminus
          ctx    = result.send(:data).to_h

          assert_call_for(signal, ctx, terminus: terminus, seq: seq, **expected_ctx_variables, **ctx_variables)
        end
      end
    end
  end
end
