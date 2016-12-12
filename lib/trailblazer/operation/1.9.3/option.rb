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
      proc.(options)
    end

    def self.call_method(proc, input, options)
      input.send(proc, options)
    end

    def self.call_callable(callable, input, options)
      callable.(options)
    end

    KW = Option
  end # Option
end
