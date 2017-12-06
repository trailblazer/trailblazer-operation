require "pp"

require "minitest/autorun"
require "trailblazer/operation"

Minitest::Spec::Activity = Trailblazer::Activity

module Test
  # Create a step method in `klass` with the following body.
  #
  #   def a(options, a_return:, data:, **)
  #     data << :a
  #
  #     a_return
  #   end
  def self.step(klass, *names)
    names.each do |name|
      method_def =
        %{def #{name}(options, #{name}_return:, data:, **)
          data << :#{name}

          #{name}_return
        end}

      klass.class_eval(method_def)
    end
  end
end





Minitest::Spec.class_eval do
  def Inspect(*args)
    Trailblazer::Activity::Inspect::Instance(*args)
  end

  def Seq(sequence)
    content =
      sequence.collect do |(magnetic_to, task, plus_poles)|
        pluses = plus_poles.collect { |plus_pole| Seq.PlusPole(plus_pole) }

%{#{magnetic_to.inspect} ==> #{Seq.Task(task)}
#{pluses.empty? ? " []" : pluses.join("\n")}}
      end.join("\n")

    "\n#{content}\n".gsub(/\d\d+/, "")
  end

  module Seq
    def self.PlusPole(plus_pole)
      signal = plus_pole.signal.to_s.sub("Trailblazer::Circuit::", "")
      semantic = plus_pole.send(:output).semantic
      " (#{semantic})/#{signal} ==> #{plus_pole.color.inspect}"
    end

    def self.Task(task)
      return task.inspect unless task.kind_of?(Trailblazer::Circuit::End)

      class_name = strip(task.class)
      name     = task.instance_variable_get(:@name)
      semantic = task.instance_variable_get(:@options)[:semantic]
      "#<#{class_name}:#{name}/#{semantic.inspect}>"
    end

    def self.strip(string)
      string.to_s.sub("Trailblazer::Circuit::", "")
    end
  end

  def Cct(process)
    hash = process.instance_variable_get(:@circuit).to_fields[0]

    content =
      hash.collect do |task, connections|
        conns = connections.collect do |signal, target|
          " {#{signal}} => #{Seq.Task(target)}"
        end

        [ Seq.Task(task), conns.join("\n") ]
      end

      content = content.join("\n")

      "\n#{content}".gsub(/\d\d+/, "")
  end

  def Ends(process)
    end_events = process.instance_variable_get(:@circuit).to_fields[1]
    ends = end_events.collect { |evt| Seq.Task(evt) }.join(",")
    "[#{ends}]".gsub(/\d\d+/, "")
  end

end
