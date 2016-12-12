class Trailblazer::Operation
  # :private:
  module Option
    def self.call(proc, &block)
      type = :proc


      option =
        if proc.is_a? Symbol
          type = :symbol
          ->(input, _options) { call_method(proc, input, _options) }
        elsif proc.is_a? Proc
          ->(input, _options) { call_proc(proc, input, _options) }
        elsif proc.is_a? Uber::Callable
          type = :callable
          ->(input, _options) { call_callable(proc, input, _options) }
        end

      yield type if block_given?
      option
    end

    def self.call_proc(proc, input, options)
      return proc.(options) if proc.arity == 1
      proc.(options, **options)
    end

    def self.call_method(proc, input, options)
      return input.send(proc, options) if input.method(proc).arity == 1 # TODO: remove this
      input.send(proc, options, **options)
    end

    def self.call_callable(callable, input, options)
      return callable.(options) if callable.method(:call).arity == 1
      callable.(options, **options)
    end
  end
end
