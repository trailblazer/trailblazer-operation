# THIS FILE IS AUTOGENERATED FROM trailblazer-activity-dsl-linear/test/docs/subprocess_test.rb
require "test_helper"

class SubprocessDocsTest < Minitest::Spec
  Memo = Class.new
  #:nested
  module Memo::Operation
    class Validate < Trailblazer::Operation
      step :check_params
      step :text_present?
      #~meths
      include T.def_steps(:check_params, :text_present?)
      #~meths end
    end
  end
  #:nested end

  #:container
  module Memo::Operation
    class Create < Trailblazer::Operation
      step Subprocess(Validate)
      step :save
      left :handle_errors
      step :notify
      #~meths
      include T.def_steps(:validate, :save, :handle_errors, :notify)
      #~meths end
    end
  end
  #:container end

  it "what" do
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :save, :notify]"
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :save, :handle_errors]", save: false, terminus: :failure
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :handle_errors]", text_present?: false, terminus: :failure
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :handle_errors]", check_params: false, terminus: :failure
  end
end

class Output_SubprocessDocsTest < Minitest::Spec
  Memo = Class.new

  module Memo::Operation
    class Validate < Trailblazer::Operation
      step :check_params
      step :text_present?
      #~meths
      include T.def_steps(:check_params, :text_present?)
      #~meths end
    end
  end

  #:container-output
  module Memo::Operation
    class Create < Trailblazer::Operation
      step Subprocess(Validate),
        Output(:failure) => Id(:notify)
      step :save
      left :handle_errors
      step :notify
      #~meths
      include T.def_steps(:validate, :save, :handle_errors, :notify)
      #~meths end
    end
  end
  #:container-output end

  it "what" do
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :save, :notify]"
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :save, :handle_errors]", save: false, terminus: :failure
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :notify]", text_present?: false
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :notify]", check_params: false
  end
end

class SubprocessDocsTest < Minitest::Spec
  Memo = Class.new
  #:nested-terminus
  module Memo::Operation
    class Validate < Trailblazer::Operation
      step :check_params,
        Output(:failure) => End(:invalid)
      step :text_present?
      #~meths
      include T.def_steps(:check_params, :text_present?)
      #~meths end
    end
  end
  #:nested-terminus end

  #:container-terminus
  module Memo::Operation
    class Create < Trailblazer::Operation
      step Subprocess(Validate),
        Output(:invalid) => Track(:failure)
      step :save
      left :handle_errors
      step :notify
      #~meths
      include T.def_steps(:validate, :save, :handle_errors, :notify)
      #~meths end
    end
  end
  #:container-terminus end

  it "what" do
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :save, :notify]"
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :save, :handle_errors]", save: false, terminus: :failure
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :handle_errors]", text_present?: false, terminus: :failure
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :handle_errors]", check_params: false, terminus: :failure
  end
end

#~ignore end

class Strict_SubprocessDocsTest < Minitest::Spec
  Memo = Class.new

  module Memo::Operation
    class Validate < Trailblazer::Operation
      step :check_params,
        Output(:failure) => End(:invalid)
      step :text_present?
      #~meths
      include T.def_steps(:check_params, :text_present?)
      #~meths end
    end
  end

  module Memo::Operation
    class Create < Trailblazer::Operation
      step Subprocess(Validate, strict: true) # no wiring of {:invalid} terminus.
      step :save
      left :handle_errors
      step :notify
      #~meths
      include T.def_steps(:validate, :save, :handle_errors, :notify)
      #~meths end
    end
  end

  it "raises {IllegalSignalError} at runtime when not connected" do
    skip "see https://github.com/trailblazer/trailblazer-activity-dsl-linear/issues/59"

    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :save, :notify]"
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :save, :handle_errors]", save: false, terminus: :failure
    assert_invoke Memo::Operation::Create, seq: "[:check_params, :text_present?, :handle_errors]", text_present?: false, terminus: :failure
    # exception = assert_raises Trailblazer::Operation::Circuit::IllegalSignalError do
      assert_invoke Memo::Operation::Create, seq: "[:check_params, :handle_errors]", check_params: false, terminus: :failure
    # end

    # assert_equal exception.message.split("\n")[1][0..82], %(\e[31mUnrecognized Signal `#<Trailblazer::Operation::End semantic=:invalid>` returned)
  end
end

class FixmeSubprocess_FailFast_DocsTest < Minitest::Spec
  Memo = Class.new
  module Memo::Operation
    class Create < Trailblazer::Operation
      step :validate,
        fail_fast: true
      step :save
      #~meths
      include T.def_steps(:validate, :save)
      #~meths end
    end
  end

  it do
    assert_invoke Memo::Operation::Create, seq: "[:validate, :save]"
    assert_invoke Memo::Operation::Create, seq: "[:validate]", terminus: :fail_fast, validate: false
  end
end

class Subprocess_FailFast_DocsTest < Minitest::Spec
  Memo = Struct.new(:id)

  module Memo::Operation
    class Validate < Trailblazer::Operation # Validate is a {Railway}
      step :validate
      include T.def_steps(:validate)
    end
  end

  module Memo::Operation
    class Create < Trailblazer::Operation
      step Subprocess(Validate), fail_fast: true
      step :save
      #~meths
      include T.def_steps(:save)
      #~meths end
    end
  end

  it do
    assert_invoke Memo::Operation::Create, seq: "[:validate, :save]"
    assert_invoke Memo::Operation::Create, seq: "[:validate]", terminus: :fail_fast, validate: false
  end
end

class Subprocess_PassFast_DocsTest < Minitest::Spec
  Memo = Struct.new(:id)

  module Memo::Operation
    class Validate < Trailblazer::Operation
      step :validate
      include T.def_steps(:validate)
    end
  end

  module Memo::Operation
    class Create < Trailblazer::Operation
      step Subprocess(Validate), pass_fast: true
      step :save
      #~meths
      include T.def_steps(:save)
      #~meths end
    end
  end

  it do
    assert_invoke Memo::Operation::Create, seq: "[:validate]", terminus: :pass_fast
    assert_invoke Memo::Operation::Create, seq: "[:validate]", terminus: :failure, validate: false
  end
end

class Subprocess_FastTrack_DocsTest < Minitest::Spec
  Memo = Struct.new(:id)

  module Memo::Operation
    class Validate < Trailblazer::Operation
      step :validate, fast_track: true
      include T.def_steps(:validate)
    end
  end

  #:subprocess-fast-track
  module Memo::Operation
    class Create < Trailblazer::Operation
      step Subprocess(Validate), fast_track: true
      step :save
      left :handle_errors
      step :notify
      #~meths
      include T.def_steps(:save, :handle_errors, :notify)
      #~meths end
    end
  end
  #:subprocess-fast-track end

  it do
    assert_invoke Memo::Operation::Create, seq: "[:validate, :save, :notify]" # validate returns {true}.
    assert_invoke Memo::Operation::Create, seq: "[:validate, :handle_errors]", validate: false, terminus: :failure # validate returns {false}.
    assert_invoke Memo::Operation::Create, seq: "[:validate]", validate: Trailblazer::Activity::FastTrack::PassFast, terminus: :pass_fast # validate returns {pass_fast!}.
    assert_invoke Memo::Operation::Create, seq: "[:validate]", validate: Trailblazer::Activity::FastTrack::FailFast, terminus: :fail_fast # validate returns {fail_fast!}.
  end
end
