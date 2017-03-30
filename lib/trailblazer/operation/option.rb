class Trailblazer::Operation
  # :private:
  module Option
    # Return task to call the option with keyword arguments. Ruby >= 2.0.
    # This is used by `Operation::step` to wrap the argument and make it
    # callable in the circuit
    def self.KW(proc)
      if proc.is_a? Symbol
        ->(*args) { meth!(proc, *args) }
      else
        ->(*args) { call!(proc, *args) }
      end
    end

    # DISCUSS: standardize tmp_options.
    def self.call!(proc, options, flow_options, tmp_options={})
      proc.(options, **options.to_hash(tmp_options))
    end

    # Make the context's instance method a "lambda" and reuse #call!.
    # TODO: should we make :context a kwarg?
    def self.meth!(proc, options, flow_options, *args)
      call!(flow_options[:context].method(proc), options, flow_options, *args)
    end
  end
end
