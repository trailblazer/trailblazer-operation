require "test_helper"

class IntrospectTest < Minitest::Spec
  A = ->(*args) { [Activity::Right, *args] }
  B = ->(*args) { [Activity::Right, *args] }
  C = ->(*args) { [Activity::Right, *args] }
  D = ->(*args) { [Activity::Right, *args] }

  let(:activity) do
    nested = bc

    Class.new(Trailblazer::Operation) do
      step A
      step nested, Output(nested.outputs.keys.first, :success) => :success
      step D, id: "D"
    end
  end

  let(:bc) do
    Class.new(Trailblazer::Operation) do
      step B
      step C
    end
  end

  describe "#collect" do
    it "iterates over each task element in the top activity" do
      skip
      all_tasks = Activity::Introspect.collect(activity) do |task, _connections|
        task
      end

      # pp all_tasks

      all_tasks.size.must_equal 8
      # all_tasks[1..3].must_equal [A, bc, D]
      # TODO: test start and end!
    end

    it "iterates over all task elements recursively" do
      skip
      all_tasks = Activity::Introspect.collect(activity, recursive: true) do |task, _connections|
        task
      end

      all_tasks.size.must_equal 9
      all_tasks[1..2].must_equal [A, bc]
      all_tasks[4..5].must_equal [B, C]
    end
  end
end
