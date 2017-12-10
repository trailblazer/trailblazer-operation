require "test_helper"

class WiringDocsTest < Minitest::Spec
  class Memo
    def initialize(options={})
      @options
    end

    def inspect
      %{#<Memo text=#{text.inspect}>}
    end

    attr_accessor :id, :text
  end

  # _"Everything's a memo."_

  module Step
    #:memo-op
    class Memo::Create < Trailblazer::Operation
      step :create_model
      step :validate
      fail :assign_errors
      step :index
      pass :uuid
      step :save
      fail :log_errors
      #~memo-methods
      def create_model(options, **)
      end
      def validate(options, **)
      end
      def assign_errors(options, **)
      end
      def index(options, **)
      end
      def uuid(options, **)
      end
      def save(options, **)
      end
      def log_errors(options, **)
      end
      #~memo-methods end
    end
    #:memo-op end

  end

  it do
    result = Memo::Create.( text: "Punk is not dead." )
  end


  module PassFast
    #:pf-op
    class Memo::Create < Trailblazer::Operation
      step :create_model
      step :validate,     pass_fast: true
      fail :assign_errors
      step :index
      pass :uuid
      step :save
      fail :log_errors
      #~pf-methods
      def create_model(options, **)
      end
      def validate(options, **)
      end
      def assign_errors(options, **)
      end
      def index(options, **)
      end
      def uuid(options, **)
      end
      def save(options, **)
      end
      def log_errors(options, **)
      end
      #~pf-methods end
    end
    #:pf-op end

  end

  module FailFast
    #:ff-op
    class Memo::Create < Trailblazer::Operation
      step :create_model
      step :validate
      fail :assign_errors, fail_fast: true
      step :index
      pass :uuid
      step :save
      fail :log_errors
      #~ff-methods
      def create_model(options, **)
      end
      def validate(options, **)
      end
      def assign_errors(options, **)
      end
      def index(options, **)
      end
      def uuid(options, **)
      end
      def save(options, **)
      end
      def log_errors(options, **)
      end
      #~ff-methods end
    end
    #:ff-op end

  end

  module FailFast
    #:ff-step-op
    class Memo::Create < Trailblazer::Operation
      step :create_model
      step :validate
      fail :assign_errors, fail_fast: true
      step :index,         fail_fast: true
      pass :uuid
      step :save
      fail :log_errors
      #~ff-step-methods
      def create_model(options, **)
      end
      def validate(options, **)
      end
      def assign_errors(options, **)
      end
      def index(options, **)
      end
      def uuid(options, **)
      end
      def save(options, **)
      end
      def log_errors(options, **)
      end
      #~ff-step-methods end
    end
    #:ff-step-op end
  end

=begin
describe all options :pass_fast, :fast_track and emiting signals directly, like Left.
=end
  module FastTrack
    class Memo < WiringDocsTest::Memo; end

    #:ft-step-op
    class Memo::Create < Trailblazer::Operation
      step :create_model,  fast_track: true
      step :validate
      fail :assign_errors, fast_track: true
      step :index
      pass :uuid
      step :save
      fail :log_errors
      #~ft-step-methods
      #:ft-create
      def create_model(options, create_empty_model:false, **)
        options[:model] = Memo.new
        create_empty_model ? Railway.pass_fast! : true
      end
      #:ft-create end
      #:signal-validate
      def validate(options, params: {}, **)
        if params[:text].nil?
          Trailblazer::Activity::Left  #=> left track, failure
        else
          Trailblazer::Activity::Right #=> right track, success
        end
      end
      #:signal-validate end
      def assign_errors(options, model:, **)
        options[:errors] = "Something went wrong!"

        model.id.nil? ? Railway.fail_fast! : false
      end
      def index(options, model:, **)
        true
      end
      def uuid(options, **)
        true
      end
      def save(options, model:, **)
        model.id = 1
      end
      def log_errors(options, **)
      end
      #~ft-step-methods end
    end
    #:ft-step-op end

    class Memo::Create2 < Memo::Create
      #:signalhelper-validate
      def validate(options, params: {}, **)
        if params[:text].nil?
          Railway.fail! #=> left track, failure
        else
          Railway.pass! #=> right track, success
        end
      end
      #:signalhelper-validate end
    end
  end

  it "runs #create_model, only" do
    Memo = FastTrack::Memo
    #:ft-call
    result = Memo::Create.( create_empty_model: true )
    puts result.success?        #=> true
    puts result[:model].inspect #=> #<Memo text=nil>
    #:ft-call end

    result.success?.must_equal true
    result[:model].id.must_be_nil
  end

  it "fast-tracks in #assign_errors" do
    Memo = FastTrack::Memo
    #:ft-call-err
    result = Memo::Create.( {} )
    puts result.success?          #=> false
    puts result[:model].inspect   #=> #<Memo text=nil>
    puts result[:errors].inspect  #=> "Something went wrong!"
    #:ft-call-err end

    result.success?.must_equal false
    result[:model].id.must_be_nil
    result[:errors].must_equal "Something went wrong!"
  end

  it "goes till #save by emitting signals directly" do
    Memo = FastTrack::Memo
    result = Memo::Create.( params: { text: "Punk is not dead!" } )
    result.success?.must_equal true
    result[:model].id.must_equal 1
    result[:errors].must_be_nil
  end

  it "goes till #save by using signal helper" do
    Memo = FastTrack::Memo
    result = Memo::Create2.( params: { text: "Punk is not dead!" } )
    result.success?.must_equal true
    result[:model].id.must_equal 1
    result[:errors].must_be_nil
  end
end
