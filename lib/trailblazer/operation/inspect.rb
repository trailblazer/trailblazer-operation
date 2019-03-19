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

    def call(operation, options = {style: :line})
      graph = Activity::Introspect::Graph(operation)

      rows = graph.collect do |node, i|
        next if node[:data][:stop_event] # DISCUSS: show this?

        created_by = node[:data][:dsl_track] || :pass

        [i, [created_by, node.id]]
      end.compact

      rows = rows[1..-1] # remove start

      return inspect_line(rows) if options[:style] == :line
      return inspect_rows(rows)
    end

    def inspect_func(step)
      @inspect[step]
    end

    Operator = {fail: "<<", pass: ">>", step: ">"}

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
