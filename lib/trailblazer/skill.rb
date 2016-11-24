# TODO: mark/make all but mutable_options as frozen.
# The idea of Skill is to have a generic, ordered read/write interface that
# collects mutable runtime-computed data while providing access to compile-time
# information.
# The runtime-data takes precedence over the class data.
module Trailblazer
  class Skill
    def initialize(mutable_options, *containers)
      @mutable_options = mutable_options
      @resolver         = Resolver.new(@mutable_options, *containers)
    end

    def [](name)
      @resolver[name]
    end

    def []=(name, value)
      @mutable_options[name] = value
    end

    # Look through a list of containers until you find the skill.
    class Resolver
    # alternative implementation:
    # containers.reverse.each do |container| @mutable_options.merge!(container) end
    #
    # benchmark, merging in #initialize vs. this resolver.
    #                merge     39.678k (± 9.1%) i/s -    198.700k in   5.056653s
    #             resolver     68.928k (± 6.4%) i/s -    342.836k in   5.001610s
      def initialize(*containers)
        @containers = containers
      end

      def [](name)
        @containers.find { |container| container.key?(name) && (return container[name]) }
      end
    end

    # private API.
    def inspect
      "<Skill #{@resolver.instance_variable_get(:@containers).collect { |c| c.inspect }.join(" ")}>"
    end
  end
end
