require "test_helper"

class KWBugsTest < Minitest::Spec
  Merchant = Struct.new(:id)

  class Merchant::New < Trailblazer::Operation
    step ->(options) { options["model"] = 1

       options["bla"] = true # this breaks Ruby 2.2.2.
     }


    step :add!
    def add!(yo:, model:, **)
      raise if model.nil?
    end
  end

  it { Merchant::New.( {}, { "yo"=> nil   } ) }
end
