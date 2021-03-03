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

    it "allows indifferent access for ctx keys" do
      #:ctx-indifferent-access
      result = Memo::Create.(params: { text: "Enjoy an IPA" })

      result[:params]     # => { text: "Enjoy an IPA" }
      result['params']    # => { text: "Enjoy an IPA" }
      #:ctx-indifferent-access end

      result.success?.must_equal true
      result[:params].must_equal({ text: "Enjoy an IPA" })
      result['params'].must_equal({ text: "Enjoy an IPA" })
    end

    it "allows defining aliases for ctx keys" do
      module AliasesExample
        Memo = Struct.new(:text)

        module Memo::Contract
          Create = Struct.new(:sync)
        end

        #:ctx-aliases-step
        class Memo::Create < Trailblazer::Operation
          #~flow
          step ->(ctx, **) { ctx[:'contract.default'] = Memo::Contract::Create.new }
          #~flow end

          pass :sync

          def sync(ctx, contract:, **)
            # ctx['contract.default'] == ctx[:contract]
            contract.sync
          end
        end
        #:ctx-aliases-step end
      end

      #:ctx-aliases
      options = { params: { text: "Enjoy an IPA" } }
      flow_options = {
        context_options: {
          aliases: { 'contract.default': :contract, 'policy.default': :policy },
          container_class: Trailblazer::Context::Container::WithAliases,
        }
      }

      # Sorry, this feature is only reliable in Ruby > 2.7
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0.0")
        result = AliasesExample::Memo::Create.(options, flow_options)
      else # Ruby 2.6 etc
        result = AliasesExample::Memo::Create.call_with_flow_options(options, flow_options)
      end

      result['contract.default']  # => Memo::Contract::Create
      result[:contract]           # => Memo::Contract::Create
      #:ctx-aliases end

      result.success?.must_equal true
      _(result[:contract].class).must_equal AliasesExample::Memo::Contract::Create
      _(result['contract.default']).must_equal result[:contract]
    end
  end

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
