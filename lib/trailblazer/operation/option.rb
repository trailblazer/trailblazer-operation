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

    def self.call!(proc, options, flow_options, tmp_options={})
      proc.(options, **options.to_hash(tmp_options))
    end

    # FIXME: sort tmp_options.
    def self.meth!(proc, options, flow_options, tmp_options={})
      flow_options[:context].send(proc, options, **options.to_hash(tmp_options))
    end
  end
end
