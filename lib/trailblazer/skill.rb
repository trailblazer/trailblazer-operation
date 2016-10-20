module Trailblazer
  class Skill
    def initialize(*containers)
      @instance_skills = {}
      # @resolver = Resolver.new(*containers)

      # we could also use Resolver here.
      containers.reverse.each do |container|
        @instance_skills.merge!(container) # FIXME: this will probably be slower than using Resolver! do some benchmarks.
      end
    end

    def [](name)
      @instance_skills[name]
    end

    def []=(name, value)
      @instance_skills[name] = value
    end

    # instead of merging runtime with class level, this might be faster.
    class Resolver
      def initialize(*containers)
        @containers = containers
      end

      # TODO: find out if runtime[name] || compiletime[name] is faster.
      def [](name)
        @containers.each { |container| return container[name] if container[name] }
      end
    end
  end
end
