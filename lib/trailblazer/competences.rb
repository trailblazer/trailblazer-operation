module Trailblazer
  class Competences
    def initialize(*containers)
      @instance_competences = {}
      # @resolver = Resolver.new(*containers)

      containers.reverse.each do |container|
        @instance_competences.merge!(container) # FIXME: this will probably be slower than using Resolver! do some benchmarks.
      end
    end

    def [](name)
      @instance_competences[name]
    end


    def []=(name, value)
      @instance_competences[name] = value
    end

    class Build
      def call(constant, &block)
        competence_class = Class.new(constant)
        competence_class.class_eval(&block) if block_given?
        # TODO: allow overriding construction.
      end
    end

    # used on operation class level.
    class Container < Hash
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
