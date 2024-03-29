# THIS FILE IS AUTOGENERATED FROM trailblazer-activity-dsl-linear/test/docs/mechanics_test.rb
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
      # #:instance-method-implicit-call end
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
    result = Memo::Operation::Create.(params: {memo: nil})
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

    result = Memo::Operation::Create.(params: {memo: nil})
    assert_equal result.success?, true

    user = Object
    assert_raises ArgumentError do
      #:kwargs-error
      result = Memo::Operation::Create.(current_user: user)
      #=> ArgumentError: missing keyword: :params
      #       memo/operation/create.rb:9:in `validate'
      #:kwargs-error end
    end
  end
end

class WriteToCtx_DocsMechanicsTest < Minitest::Spec
  class Memo
    def initialize(*); end
  end
  it "what" do
    #:ctx-write-read
    module Memo::Operation
      class Create < Trailblazer::Operation
        step :validate
        step :save # sets ctx[:model]
        step :notify
        #~body
        #~meths
        def validate(ctx, params:, **)
          true
        end

        def send_email(*)
          true
        end
        #~meths end
        #:ctx-write
        def save(ctx, params:, **)
          ctx[:model] = Memo.new(params[:memo])
        end
        #~body end
        #:ctx-write end
        def notify(ctx, model:, **)
          send_email(model)
        end
      end
    end
    #:ctx-write-read end

    #:result-read
    result = Memo::Operation::Create.(params: {memo: {content: "remember that"}})

    result[:model] #=> #<Memo id: 1, ...>
    #:result-read end

    #:result-success
    puts result.success? #=> true
    #:result-success end

    assert_equal result[:model].class, Memo
    assert_equal result.success?, true

    user = Object
    assert_raises ArgumentError do
      #:kwargs-error
      result = Memo::Operation::Create.(current_user: user)
      #=> ArgumentError: missing keyword: :params
      #       memo/operation/create.rb:9:in `validate'
      #:kwargs-error end
    end
  end
end

class ReturnValueSuccess_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    module Memo::Operation
      class Create < Trailblazer::Operation
        step :validate
        #~meths
        step :save

        def save(*); true; end
        #~meths end
        #:return-success
        def validate(ctx, params:, **)
          params.key?(:memo) # => true/false
        end
        #:return-success end
      end
    end

    result = Memo::Operation::Create.(params: {memo: nil})
    assert_equal result.success?, true
  end
end

class ReturnValueFailure_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    module Memo::Operation
      class Create < Trailblazer::Operation
        step :validate
        #~meths
        step :save

        def save(*); true; end
        #~meths end
        #:return-failure
        def validate(ctx, params:, **)
          nil
        end
        #:return-failure end
      end
    end

    result = Memo::Operation::Create.(params: {memo: nil})
    assert_equal result.success?, false
  end
end

class ReturnSignal_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    #:signal-operation
    module Memo::Operation
      class Create < Trailblazer::Operation
        class NetworkError < Trailblazer::Activity::Signal
        end
        #~meths
        #:signal-steps
        step :validate
        step :save
        left :handle_errors
        step :notify,
          Output(NetworkError, :network_error) => End(:network_error)
        #:signal-steps end
        def save(ctx, **)
          ctx[:model] = Object
        end
        def validate(ctx, params:, **)
          true
        end
        def send_email(model)
          true
        end
        def check_network(params)
          ! params[:network_broken]
        end

        #:return-signal
        def notify(ctx, model:, params:, **)
          return NetworkError unless check_network(params)

          send_email(model)
        end
        #:return-signal end
        #~meths end
      end
    end
    #:signal-operation end

    result = Memo::Operation::Create.(params: {memo: nil, network_broken: false})
    assert_equal result.success?, true

    #:terminus
    result = Memo::Operation::Create.(params: {memo: nil, network_broken: true})

    result.terminus.to_h[:semantic] #=> :network_error
    #:terminus end
    assert_equal result.success?, false
    assert_equal result.terminus.to_h[:semantic], :network_error

    #:terminus-subprocess
    module Endpoint
      class API < Trailblazer::Operation
        step Subprocess(Memo::Operation::Create),
          Output(:network_error) => Track(:failure)
        # ...
      end
    end
    #:terminus-subprocess end
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

class Inheritance_DocsMechanicsTest < Minitest::Spec
  Memo = Module.new
  it "what" do
    #:inherit-create
    module Memo::Operation
      class Create < Trailblazer::Operation
        step :create_model
        step :validate
        step :save
        #~meths
        include T.def_steps(:create_model, :validate, :save)
        #~meths end
      end
    end
    #:inherit-create end

    #:inherit-update-empty
    module Memo::Operation
      class Update < Create
      end
    end
    #:inherit-update-empty end

    #:inherit-update
    module Memo::Operation
      class Update < Create
        step :find_model, replace: :create_model
        #~meths
        include T.def_steps(:find_model)
        #~meths end
      end
    end
    #:inherit-update end

    assert_invoke Memo::Operation::Create, seq: "[:create_model, :validate, :save]"
    assert_invoke Memo::Operation::Update, seq: "[:find_model, :validate, :save]"
  end
end

