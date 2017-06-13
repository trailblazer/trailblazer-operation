module Trailblazer
  # Operation-specific circuit rendering. This is optimized for a linear railway circuit.
  #:private:
  module Operation::Inspect
    module_function

    # TODO: at some point, we should render the real circuit graph using circuit tools.
    def call(operation, options={ style: :line })
      rows = operation["__sequence__"].each_with_index.collect { |row, i| [ i, [ row.incoming_direction, row.name ] ]  }

      return inspect_line(rows) if options[:style] == :line
      return inspect_rows(rows)
    end

    def inspect_func(step)
      @inspect[step]
    end

    Operator = { Circuit::Left => "<", Circuit::Right => ">", }

    def inspect_line(names)
      string = names.collect { |i, (track, name)| "#{Operator[track]}#{name}" }.join(",")
      "[#{string}]"
    end

    def inspect_rows(names)
      string = names.collect do |i, (track, name)|
        operator = Operator[track]

        op = "#{operator}#{name}"
        padding = 38

        proc = if operator == "<"
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
