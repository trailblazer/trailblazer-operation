require "test_helper"

class Wtf_DeveloperDocsTest < Minitest::Spec
  Memo = Class.new
  module Memo::Operation
    class Create < Trailblazer::Operation
      step :validate
      step :save
      left :handle_errors
      step :notify
      #~meths
      include T.def_steps(:validate, :save, :handle_errors, :notify)
      #~meths end
    end
  end

  it "what" do
    #:wtf
    result = Memo::Operation::Create.wtf?(
      #~meths
      seq: [],
      #~meths end
      params: {memo: "remember me!"}
    )
    #:wtf end
  end
end
