module Trailblazer
  module Operation::Railway
    # This behavior used to be part of [Pipetree::Step](https://github.com/trailblazer/trailblazer-operation/blob/31e122f1787b72835d52a8a127c718ab49ee51e4/lib/trailblazer/operation/pipetree.rb#L129).
    module Injection
    end

    # TODO: writes hard to options.
    # TODO: add Context and Uninject.
    def self.Inject(dependencies)
      task = ->(direction, options, flow_options, *args) do
        dependencies.each { |k, v| options[k] ||= v }

        [direction, options, flow_options, *args]
      end
    end
  end
end
