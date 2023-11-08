require "test_helper"

module Y
  class DocsMechanicsTest < Minitest::Spec
    Memo = Module.new
    it "what" do
      #:instance-method
      module Memo::Operation
        class Create < Trailblazer::Operation
          step :validate

          #~meths
          def validate(ctx, params:, **)
            params.key?(:memo) ? true : false # return value matters!
          end
          #~meths end
        end
      end
      #:instance-method end

      #:instance-method-call
      result = Memo::Operation::Create.call(params: {memo: nil})
      #:instance-method-call end
      assert_equal result.success?, true

      #:instance-method-implicit-call
      result = Memo::Operation::Create.(params: {memo: nil})
      #:instance-method-implicit-call end
      assert_equal result.success?, true
    end
  end
end

class ReadfromCtx_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    #:ctx-read
    module Memo::Operation
      class Create < Trailblazer::Operation
        step :validate
        #~meths
        step :save

        def save(*); true; end
        #~meths end
        def validate(ctx, **)
          p ctx[:params] #=> {:memo=>nil}
        end
      end
    end
    #:ctx-read end

    #:ctx-read-call
    result = Memo::Operation::Create.call(params: {memo: nil})
    #:ctx-read-call end
    assert_equal result.success?, true
  end
end

class ReadfromCtxKwargs_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    module Memo::Operation
      class Create < Trailblazer::Operation
        step :validate
        #~meths
        step :save

        def save(*); true; end
        #~meths end
        #:ctx-read-kwargs
        def validate(ctx, params:, **)
          p params #=> {:memo=>nil}
        end
        #:ctx-read-kwargs end
      end
    end

    result = Memo::Operation::Create.call(params: {memo: nil})
    assert_equal result.success?, true
  end
end


class Classmethod_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    #:class-method
    module Memo::Operation
      class Create < Trailblazer::Operation
        #~meths
        # Define {Memo::Operation::Create.validate}
        def self.validate(ctx, params:, **)
          params.key?(:memo) ? true : false # return value matters!
        end
        #~meths end

        step method(:validate)
      end
    end
    #:class-method end
  end
end

class Module_Classmethod_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    #:module-step
    # Reusable steps in a module.
    module Steps
      def self.validate(ctx, params:, **)
        params.key?(:memo) ? true : false # return value matters!
      end
    end
    #:module-step end

    #:module-method
    module Memo::Operation
      class Create < Trailblazer::Operation
        step Steps.method(:validate)
      end
    end
    #:module-method end
  end
end

class Callable_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    #:callable-step
    module Validate
      def self.call(ctx, params:, **)
        valid?(params) ? true : false # return value matters!
      end

      def valid?(params)
        params.key?(:memo)
      end
    end
    #:callable-step end

    #:callable-method
    module Memo::Operation
      class Create < Trailblazer::Operation
        step Validate
      end
    end
    #:callable-method end
  end
end

class Lambda_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    #:lambda-step
    module Memo::Operation
      class Create < Trailblazer::Operation
        step ->(ctx, params:, **) { p params.inspect }
      end
    end
    #:lambda-step end
  end
end
