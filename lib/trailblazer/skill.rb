module Trailblazer
  class Skill
    def initialize(*containers)
      @instance_skills = {}
      @resolver = Resolver.new(@instance_skills, *containers)

      # we could also use Resolver here.
      # containers.reverse.each do |container|
      #   @instance_skills.merge!(container) # FIXME: this will probably be slower than using Resolver! do some benchmarks.
      # end
    end

    def [](name)
      @resolver[name]
    end

    def []=(name, value)
      @instance_skills[name] = value
    end

    # Look through a list of containers until you find the skill.
    class Resolver
    # benchmark, merging in #initialize vs. this resolver.
    #                merge     39.678k (± 9.1%) i/s -    198.700k in   5.056653s
    #             resolver     68.928k (± 6.4%) i/s -    342.836k in   5.001610s
      def initialize(*containers)
        @containers = containers
      end

      def [](name)
        # @containers.each { |container| return container[name] if container[name] }
        result = @containers.find { |container| val = container[name] and (return val) }
      end
    end
  end
end
