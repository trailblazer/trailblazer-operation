require "test_helper"

module A
  class DocsStepTest < Minitest::Spec
    Memo = Module.new

    #:railway
    module Memo::Operation
      class Create < Trailblazer::Operation
        step :validate
        step :save
        #~step
        left :handle_errors
        #~left
        step :notify
        #~meths
        # fail :log_error
        # step :save
        def validate(ctx, params:, **)
          ctx[:input] = Form.validate(params) # true/false
        end

        # def create(ctx, input:, create:, **)
        #   create
        # end

        # def log_error(ctx, logger:, params:, **)
        #   logger.error("wrong params: #{params.inspect}")
        # end
        #~meths end
      end
    end
        #~step end
        #~left end
    #:railway end

    # it "what" do
    #   ctx = {params: {text: "Hydrate!"}, create: true}
    #   signal, (ctx, _flow_options) = D::Create.([ctx, {}])
    # end
  end
end


module B
  class DocsStepTest < Minitest::Spec
    Memo = Module.new

    #:fail
    module Memo::Operation
      class Create < Trailblazer::Operation
        step :validate
        step :save
        fail :handle_errors # just like {#left}
        #~meths
        step :notify
        include T.def_steps(:validate, :save, :handle_errors, :notify)
        #~meths end
      end
    end
    #:fail end

    it "what" do
      assert_invoke Memo::Operation::Create, seq: "[:validate, :save, :notify]"
      assert_invoke Memo::Operation::Create, validate: false, terminus: :failure, seq: "[:validate, :handle_errors]"
    end
  end
end
