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
      # options[:prefix]
      # options[:class]
      def call(options, name=nil, constant=nil, &block)
        # contract MyForm
        if name.is_a?(Class)
          constant = name
          name = nil
        end

        # contract do .. end
        # contract :params do .. end
        # => default to e.g. Reform::Form or Disposable::Twin.
        constant = options[:class] if constant.nil? && block_given?

        path = path_name(options[:prefix], name)

        competence = Class.new(constant) if constant
        competence.class_eval(&block) if block_given?

        [path, competence]
      end

    private
      def path_name(prefix, name)
        [prefix, name, "class"].compact.join(".") # "contract.class" for default, otherwise "contract.params.class" etc.
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
