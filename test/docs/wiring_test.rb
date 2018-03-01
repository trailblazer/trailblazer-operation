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

=begin
:before, :after, :replace, :delete, :group, :id
=end
class WiringsDocSeqOptionsTest < Minitest::Spec
  module Id
    class Memo < WiringDocsTest::Memo; end

    #:id
    class Memo::Create < Trailblazer::Operation
      step :create_model, id: "create_memo"
      step :validate,     id: "validate_params"
      step :save
      #~id-methods
      def create_model(options, **)
      end
      def validate(options, **)
      end
      def save(options, **)
      end
      #~id-methods end
    end
    #:id end

    #:delete
    class Memo::Create::Admin < Memo::Create
      step nil, delete: "validate_params", id: ""
    end
    #:delete end

    #:before
    class Memo::Create::Authorized < Memo::Create
      step :policy, before: "create_memo"
      #~before-methods
      def policy(options, **)
      end
      #~before-methods end
    end
    #:before end

    #:after
    class Memo::Create::Logging < Memo::Create
      step :logger, after: "validate_params"
      #~after-methods
      def logger(options, **)
      end
      #~after-methods end
    end
    #:after end

    #:replace
    class Memo::Update < Memo::Create
      step :find_model, replace: "create_memo", id: "update_memo"
      #~replace-methods
      def find_model(options, **)
      end
      #~replace-methods end
    end
    #:replace end
  end

  it ":id shows up in introspect" do
    Memo = Id::Memo
    #:id-inspect
    Trailblazer::Operation.introspect( Memo::Create )
    #=> [>create_memo,>validate_params,>save]
    #:id-inspect end

    Trailblazer::Operation.introspect( Memo::Create ).must_equal %{[>create_memo,>validate_params,>save]}
  end

  it ":delete removes step" do
    Memo = Id::Memo
    #:delete-inspect
    Trailblazer::Operation.introspect( Memo::Create::Admin )
    #=> [>create_model,>save]
    #:delete-inspect end

    Trailblazer::Operation.introspect( Memo::Create::Admin ).must_equal %{[>create_memo,>save]}
  end

  it ":before inserts" do
    Memo = Id::Memo
    #:before-inspect
    Trailblazer::Operation.introspect( Memo::Create::Authorized )
    #=> [>create_model,>save]
    #:before-inspect end

    Trailblazer::Operation.introspect( Memo::Create::Authorized ).must_equal %{[>policy,>create_memo,>validate_params,>save]}
  end

  it ":after inserts" do
    Memo = Id::Memo
    #:after-inspect
    Trailblazer::Operation.introspect( Memo::Create::Logging )
    #=> [>create_memo,>validate_params,>logger,>save]
    #:after-inspect end

    Trailblazer::Operation.introspect( Memo::Create::Logging ).must_equal %{[>create_memo,>validate_params,>logger,>save]}
  end

  it ":replace inserts" do
    Memo = Id::Memo
    #:replace-inspect
    Trailblazer::Operation.introspect( Memo::Update )
    #=> [>update_memo,>validate_params,>save]
    #:replace-inspect end

    Trailblazer::Operation.introspect( Memo::Update ).must_equal %{[>update_memo,>validate_params,>save]}
  end
end

# @see https://github.com/trailblazer/trailblazer/issues/190#issuecomment-326992255
class WiringsDocRecoverTest < Minitest::Spec
  Memo = WiringDocsTest::Memo

  #:fail-success
  class Memo::Upload < Trailblazer::Operation
    step :upload_to_s3
    fail :upload_to_azure,  Output(:success) => Track(:success)
    fail :upload_to_b2,     Output(:success) => Track(:success)
    fail :log_problem
    #~methods
    #:fail-success-s3
    def upload_to_s3(options, s3:, **)
      options[:s3] = s3 # the actual upload is dispatched here and result collected.
    end
    #:fail-success-s3 end

    def upload_to_azure(options, azure:, **)
      options[:azure] = azure
    end

    def upload_to_b2(options, b2:, **)
      options[:b2] = b2
    end

    def log_problem(options, **)
      options[:problem] = "All uploads failed."
    end
    #~methods end
  end
  #:fail-success end

  let(:my_image) { "beautiful landscape" }

  it "works for S3" do
    result = Memo::Upload.( image: my_image, s3: true )

    [ result.success?, result[:s3], result[:azure], result[:b2], result[:problem] ].must_equal [ true, true, nil, nil, nil ]
  end

  it "works for Azure" do
    result = Memo::Upload.( image: my_image, azure: true, s3: false )

    [ result.success?, result[:s3], result[:azure], result[:b2], result[:problem] ].must_equal [ true, false, true, nil, nil ]
  end

  it "works for B2" do
    result = Memo::Upload.( image: my_image, b2: true, azure: false, s3: false )

    [ result.success?, result[:s3], result[:azure], result[:b2], result[:problem] ].must_equal [ true, false, false, true, nil ]
  end

  it "fails for all" do
    result = Memo::Upload.( image: my_image, b2: false, azure: false, s3: false )

    [ result.success?, result[:s3], result[:azure], result[:b2], result[:problem] ].must_equal [ false, false, false, false, "All uploads failed." ]
  end
end

class WiringsDocCustomConnectionTest < Minitest::Spec
  Memo = Class.new(WiringDocsTest::Memo)

  #:target-id
  class Memo::Upload < Trailblazer::Operation
    step :new?, Output(:failure) => "index"
    step :upload
    step :validate
    fail :validation_error
    step :index, id: "index"
    #~target-id-methods
    def new?(options, is_new:, **)
      options[:new?] = is_new
    end

    def upload(options, **)
      options[:upload] = true
    end

    def validate(options, validate:true, **)
      options[:validate] = validate
    end

    def validation_error(options, **)
      options[:validation_error] = true
    end

    def index(options, **)
      options[:index] = true
    end
    #~target-id-methods end
  end
  #:target-id end

  let(:my_image) { "beautiful landscape" }

  it "works with new image" do
    result = Memo::Upload.( image: my_image, is_new: true )
    result.inspect(:new?, :upload, :validate, :validation_error, :index).must_equal %{<Result:true [true, true, true, nil, true] >}
  end

  it "skips everything but index for existing image" do
    result = Memo::Upload.( image: my_image, is_new: false )
    result.inspect(:new?, :upload, :validate, :validation_error, :index).must_equal %{<Result:true [false, nil, nil, nil, true] >}
  end

  it "fails in validation" do
    result = Memo::Upload.( image: my_image, is_new: true, validate: false )
    result.inspect(:new?, :upload, :validate, :validation_error, :index).must_equal %{<Result:false [true, true, false, true, nil] >}
  end
end

class WiringsDocDeciderTest < Minitest::Spec
  Memo = Class.new(WiringDocsTest::Memo)

  #:decider
  class Memo::Upsert < Trailblazer::Operation
    step :find_model, Output(:failure) => Track(:create_route)
    step :update
    step :create, magnetic_to: [:create_route]
    step :save
    #~methods
    def find_model(options, id:nil, **)
      options[:model] = Memo.find(id)
    end

    def find_model(options, id:, **)
      options[:find_model] = id
    end
    def update(options, **)
      options[:update] = true
    end
    def create(options, **)
      options[:create] = true
    end
    def save(options, **)
      options[:save] = true
    end
    #~methods end
  end
  #:decider end

  it "goes the create route" do
    Memo::Upsert.( id: false ).inspect(:find_model, :update, :create, :save).must_equal %{<Result:true [false, nil, true, true] >}
  end

  it "goes the update route" do
    Memo::Upsert.( id: true ).inspect(:find_model, :update, :create, :save).must_equal %{<Result:true [true, true, nil, true] >}
  end
end

class WiringsDocEndTest < Minitest::Spec
  Memo = Class.new(WiringDocsTest::Memo)

  #:end
  class Memo::Update < Trailblazer::Operation
    step :find_model, Output(:failure) => End(:model_not_found)
    step :update
    fail :db_error
    step :save
    #~methods
    def find_model(options, id:nil, **)
      options[:model] = Memo.find(id)
    end

    def find_model(options, id:, **)
      options[:find_model] = id
    end
    def update(options, update: true, **)
      options[:update] = update
    end
    def db_error(options, **)
      options[:db_error] = 1
    end
    def save(options, **)
      options[:save] = true
    end
    #~methods end
  end
  #:end end

  it "goes success path" do
    Memo::Update.( id: true ).inspect(:find_model, :update, :save, :db_error).must_equal %{<Result:true [true, true, true, nil] >}
  end

  it "errors out on End.model_not_found" do
    result = Memo::Update.( id: false )
    result.inspect(:find_model, :update, :save, :db_error).must_equal %{<Result:false [false, nil, nil, nil] >}
    result.event.to_h.must_equal(semantic: :model_not_found)
  end

  it "takes normal error track" do
    result = Memo::Update.( id: true, update: false )
    result.inspect(:find_model, :update, :save, :db_error).must_equal %{<Result:false [true, false, nil, 1] >}
    result.event.to_h.must_equal(semantic: :failure)
  end
end
