require "test_helper"

class MacaroniTaskBuilderTest < Minitest::Spec
  Memo = Struct.new(:title) do
    def save
      self.title = title[:title].reverse
    end
  end

  #:create
  class Memo::Create < Trailblazer::Operation
    #~ign
    Normalizer, _ = Trailblazer::Activity::Magnetic::Normalizer.build( task_builder: Railway::KwSignature, pipeline: Railway::Normalizer::Pipeline )

    step :create_model, normalizer: Normalizer
    step :save,         normalizer: Normalizer
    #~ign end
    #~methods
    def create_model( params:, options:, ** )
      options[:model] = Memo.new( title: params[:title] )
    end

    def save( model:, ** )
      model.save
    end
    #~methods end
  end
  #:create end

  it "allows optional macaroni call style" do
    Memo::Create.( params: { title: "Wow!" } ).inspect(:model).must_equal %{<Result:true [#<struct MacaroniTaskBuilderTest::Memo title=\"!woW\">] >}
  end
end
