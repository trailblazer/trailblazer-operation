module Trailblazer
  module Operation::Container
    def options_for_public_call(options={}, *containers)
      # generate the skill hash that embraces runtime options plus potential containers, the so called Runtime options.
      # This wrapping is supposed to happen once in the entire system.

      hash_transformer = ->(containers) { containers[0].to_hash } # FIXME: don't transform any containers into kw args.

      immutable_options = Trailblazer::Context::ContainerChain.new([options, *containers], to_hash: hash_transformer)

      Trailblazer::Context(immutable_options)
    end
  end
end
