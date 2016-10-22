module Trailblazer
  class Skill
    def initialize(mutuable_options, *containers)
      @mutuable_options = mutuable_options
      @resolver         = Resolver.new(@mutuable_options, *containers)
    end

    def [](name)
      @resolver[name]
    end

    def []=(name, value)
      @mutuable_options[name] = value
    end

    # Look through a list of containers until you find the skill.
    class Resolver
    # alternative implementation:
    # containers.reverse.each do |container| @mutuable_options.merge!(container) end
    #
    # benchmark, merging in #initialize vs. this resolver.
    #                merge     39.678k (± 9.1%) i/s -    198.700k in   5.056653s
    #             resolver     68.928k (± 6.4%) i/s -    342.836k in   5.001610s
      def initialize(*containers)
        @containers = containers
      end

      def [](name)
        @containers.find { |container| val = container[name] and (return val) }
      end
    end

    # private API.
    def inspect
      "<Skill #{@resolver.instance_variable_get(:@containers).collect { |c| c.inspect }.join(" ")}>"
    end
  end
end
