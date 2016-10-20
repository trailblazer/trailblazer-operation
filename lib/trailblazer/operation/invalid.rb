module Trailblazer::Operation::Invalid
  def invalid!
    result[:valid] = false
  end
end
