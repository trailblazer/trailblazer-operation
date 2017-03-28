class Trailblazer::Operation
  # :private:
  # This code is not beautiful, but could also be worse.
  # I'm expecting some of this to go to Uber, as we use this pattern everywhere.
  class Option
    def self.call(proc, &block)
      type = :proc

      option =
        if proc.is_a? Symbol
          type = :symbol
          ->(input, *_options) { call_method(proc, input, *_options) }
        elsif proc.is_a? Proc
          ->(input, *_options) { call_proc(proc, input, *_options) }
        elsif proc.is_a? Uber::Callable
          type = :callable
          ->(input, *_options) { call_callable(proc, input, *_options) }
        end

      yield type if block_given?
      option
    end

    def self.call_proc(proc, input, *options)
      proc.(*options)
    end

    def self.call_method(*args)
      raise args.inspect
      input.send(proc, *options)
    end

    def self.call_callable(callable, input, *options)
      callable.(*options)
    end

    # Call the option with keyword arguments. Ruby >= 2.0.
    class KW < Option
      def self.call_proc(proc, options, flow_options, tmp_options={})
        proc.(options, **options.to_hash(tmp_options))
      end

      # FIXME: sort tmp_options.
      def self.call_method(proc, options, flow_options, tmp_options={})
        flow_options[:context].send(proc, options, **options.to_hash(tmp_options))
      end
    end
  end
end
