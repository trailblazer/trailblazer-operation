require "test_helper"

class DocsActivityTest < Minitest::Spec
  Memo = Struct.new(:text)

  #:memo
  class Memo::Create < Trailblazer::Operation
    step :create_model

    def create_model(ctx, params:, **)
      ctx[:model] = Memo.new(params[:text])
    end
  end
  #:memo end

  it "what" do
    #:call-circuit
    ctx = {params: {text: "Enjoy an IPA"}}
    signal, (ctx, _) = Memo::Create.([ctx, {}], {})

    puts signal #=> #<Trailblazer::Activity::Railway::End::Success semantic=:success>
    #:call-circuit end

    signal.inspect.must_equal %{#<Trailblazer::Activity::Railway::End::Success semantic=:success>}
  end

  #:describe
  describe Memo::Create do
    it "creates a sane Memo instance" do
      #:call-public
      result = Memo::Create.(params: {text: "Enjoy an IPA"})

      puts result.success?    #=> true

      model = result[:model]
      puts model.text         #=> "Enjoy an IPA"
      #:call-public end

      result.success?.must_equal true
      result[:model].text.must_equal "Enjoy an IPA"
    end
  end
  #:describe end

  it do
    module J
      Memo = Struct.new(:id)

      #:op
      class Create < Trailblazer::Operation
        #~flow
        step :validate, fast_track: true
        fail :log_error
        step :create
        #~flow end

        #~mod
        def create(ctx, **)
          ctx[:model] = Memo.new
        end
        #~rest
        def validate(ctx, params:, **)
          ctx[:input] # true/false
          true
        end

        def log_error(ctx, params:, **)
          logger.error("wrong params: #{params.inspect}")
          true
        end
        #~rest
        #~mod end
      end
      #:op end
    end

    ctx = {params: {text: "Hydrate!"}}
    result = J::Create.(ctx)

    result.success?.must_equal true
    # ctx.inspect.must_equal %{{:params=>{:text=>\"Hydrate!\"}, :create=>true}}

    #:op-result
    result.success? #=> true
    result[:model]  #=> #<Memo ..>
    #:op-result end
  end
end
