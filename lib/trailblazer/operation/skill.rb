# Dependencies can be defined on the operation. class level
class Trailblazer::Operation
  module Skill
    # The class-level skill container: Operation::[], ::[]=.
    module Accessors
      # :private:
      def skills
        @skills ||= {}
      end

      extend Forwardable
      def_delegators :skills, :[], :[]=
    end
  end

  module ClassDependencies
    def __call__( (ctx, flow_options), **circuit_options )
      # FIXME: this is, of course, prototyping. i want to get rid of this.
      class_options = @skills
      ctx.instance_variable_get(:@wrapped_options).instance_variable_get(:@containers).insert(1, class_options)
      super
    end
  end
end
