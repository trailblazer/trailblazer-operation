module Trailblazer
  class Skill
      # FIXME: Trailblazer::Skill()
    # @return
    def self.new(*containers)
      containers = Trailblazer::Context::ContainerChain.new(*containers)
    end

    # THIS METHOD IS CONSIDERED PRIVATE AND MIGHT BE REMOVED.
    # Options from ::call (e.g. "user.current"), containers, etc.
    # NO mutable data from the caller operation. no class state.
    # def to_runtime_data
    #   @resolver.instance_variable_get(:@containers).slice(0..-1) # FIXME. wtf are we doing here?
    # end

    # # THIS METHOD IS CONSIDERED PRIVATE AND MIGHT BE REMOVED.
    # def to_mutable_data
    #   @mutable_options
    # end
  end
end
