require "test_helper"

require "trailblazer/operation/railway/macaroni"

class MacaroniTaskBuilderTest < Minitest::Spec
  module Memo; end

  class Memo::Create < Trailblazer::Operation
    Normalizer = Railway::Normalizer.new( task_builder: Railway::Macaroni )

    step :create_model, normalizer: Normalizer
    step :save,         normalizer: Normalizer

    def create_model(params:, options:, **)
      options[:model] = params[:title]
    end

    def save(model:, **)
      model.reverse!
    end
  end

  it "allows optional macaroni call style" do
    Memo::Create.( params: { title: "Wow!" } ).inspect(:model).must_equal %{<Result:true ["!woW"] >}
  end
end
