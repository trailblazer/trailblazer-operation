module Trailblazer
  # Operation-specific circuit rendering. This is optimized for a linear railway circuit.
  #
  # @private
  #
  # NOTE: this is absolutely to be considered as prototyping and acts more like a test helper ATM as
  # Inspect is not a mission-critical part.
  class Operation
    def self.introspect(*args)
      Operation::Inspect.(*args)
    end
  end

  module Operation::Inspect
    module_function

    def call(operation, options={ style: :line })
      # TODO: better introspection API.

      alterations = Activity::Magnetic::Builder::Finalizer.adds_to_alterations(operation.to_h[:adds])
      # DISCUSS: any other way to retrieve the Alterations?

      # pp alterations
      railway = alterations.instance_variable_get(:@groups).instance_variable_get(:@groups)[:main]

      rows = railway.each_with_index.collect do |element, i|
        magnetic_to, task, plus_poles = element.configuration

        created_by =
          if magnetic_to == [:failure]
            :fail
          elsif plus_poles.size > 1
            plus_poles[0].color == plus_poles[1].color ? :pass : :step
          else
            :pass # this is wrong for Nested, sometimes
          end

        [ i, [ created_by, element.id ] ]
      end

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
