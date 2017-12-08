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

  # The use of this module is not encouraged and it is only here for backward-compatibility.
  # Instead, please pass dependencies via containers, locals, or macros into the respective steps.
  module ClassDependencies
    def __call__( (ctx, flow_options), **circuit_options )
      @skills.each { |name, value| ctx[name] ||= value } # this resembles the behavior in 2.0. we didn't say we liked it.

      super
    end
  end
end
