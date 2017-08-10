module Trailblazer
  module Hash
    def self.inspect(hash, *keys)
      ::Hash[ keys.collect { |key| [key, hash[key]] } ].inspect
    end
  end

  # Operation-specific circuit rendering. This is optimized for a linear railway circuit.
  #
  # @private
  # This is absolutely not to be copied or used for introspection as the API will definitely change
  # here. Instead of going through the sequence, we have to traverse the actual circuit graph instead.
  module Operation::Inspect
    module_function

    # TODO: at some point, we should render the real circuit graph using circuit tools.
    def call(operation, options={ style: :line })
      rows = operation["__sequence__"].each_with_index.collect { |task_wiring, i| [ i, [ task_wiring.meta_data[:created_by], task_wiring.meta_data[:id] ] ]  }

      return inspect_line(rows) if options[:style] == :line
      return inspect_rows(rows)
    end

    def inspect_func(step)
      @inspect[step]
    end

    Operator = { :fail => "<<", :pass => ">>", :step => ">"}

    def inspect_line(names)
      string = names.collect { |i, (end_of_edge, name)| "#{Operator[end_of_edge]}#{name}" }.join(",")
      "[#{string}]"
    end

    def inspect_rows(names)
      string = names.collect do |i, (end_of_edge, name)|
        operator = Operator[end_of_edge]

        op = "#{operator}#{name}"
        padding = 38

        proc = if operator == "<<"
          sprintf("%- #{padding}s", op)
        elsif [">", ">>", "&"].include?(operator.to_s)
          sprintf("% #{padding}s", op)
        else
          pad = " " * ((padding - op.length) / 2)
          "#{pad}#{op}#{pad}"
        end

        proc = proc.gsub(" ", "=")

        sprintf("%2d %s", i, proc)
      end.join("\n")
      "\n#{string}"
    end
  end
end
