class Trailblazer::Operation
  # :private:
  module Option
    # Call the option with keyword arguments. Ruby >= 2.0.
    class KW
      def self.call(proc, &block)
        type = :proc

        option =
          if proc.is_a? Symbol
            type = :symbol
            ->(input, *_options) { call_method(proc, input, *_options) }
          else
            type = :callable
            ->(input, *_options) { call_proc(proc, input, *_options) }
          end

        yield type if block_given?
        option
      end

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
