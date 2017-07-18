# TODO: mark/make all but mutable_options as frozen.
# The idea of Skill is to have a generic, ordered read/write interface that
# collects mutable runtime-computed data while providing access to compile-time
# information.
# The runtime-data takes precedence over the class data.
module Trailblazer
  class Skill
    def initialize(*containers) # usually [ params=>{}, {} ]
      @mutable_options = {}
      @resolver        = Resolver.new(@mutable_options, *containers)
    end

    def [](name)
      @resolver[name]
    end

    def []=(name, value)
      @mutable_options[name] = value
    end

    def key?(name) # FIXME: to nest skills in skills, which is totally fine.
      @resolver.key?(name)
    end

    # THIS METHOD IS CONSIDERED PRIVATE AND MIGHT BE REMOVED.
    # Options from ::call (e.g. "user.current"), containers, etc.
    # NO mutable data from the caller operation. no class state.
    def to_runtime_data
      @resolver.instance_variable_get(:@containers).slice(0..-1) # FIXME. wtf are we doing here?
    end

    # THIS METHOD IS CONSIDERED PRIVATE AND MIGHT BE REMOVED.
    def to_mutable_data
      @mutable_options
    end

    # Called when Ruby transforms options into kw args, via **options.
    # TODO: this method has massive potential for speed improvements.
    # The `tmp_options` argument is experimental. It allows adding temporary options
    # to the kw args.
    #:private:
    def to_hash(tmp_options={})
      {}.tap do |h|
        arr = to_runtime_data << to_mutable_data << tmp_options

        arr.each { |hsh|
          if hsh.is_a?(Trailblazer::Skill)
            h.merge!(hsh.to_hash)
          else
            hsh.
              to_hash.  # DISCUSS: this can be Context#to_hash
              each { |k, v| h[k.to_sym] = v }
          end
        }
      end
    end

    # TODO: use with to_hash.
    def self.KeywordHash(hash)
      h = {}
      hash.each { |k, v| h[k.to_sym] = v }
      h
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

      def key?(name)
        @containers.find { |container| container.key?(name) }
      end
    end

    # private API.
    def inspect
      "<Skill #{@resolver.instance_variable_get(:@containers).collect { |c| c.inspect }.join(" ")}>"
    end
  end
end
