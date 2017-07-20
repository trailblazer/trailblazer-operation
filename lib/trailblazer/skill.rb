module Trailblazer
  class Skill
      # FIXME: Trailblazer::Skill()
    # @return
    def self.new(*containers)
      containers = Trailblazer::Context::ContainerChain.new(*containers)
    end
  end
end
