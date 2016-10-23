module Trailblazer::Operation::Invalid
  def invalid!
    self[:valid] = false
  end
end
