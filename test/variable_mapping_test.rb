require "test_helper"

# Test input- and output filter for specific tasks.
# These are task wrap steps added before and after the task.
class VariableMappingTest < Minitest::Spec
  # first task
  Model = ->((options, flow), **o) do
    options["a"]        = options["a"] * 2 # rename to model.a
    options["model.nonsense"] = true       # filter me out

    [Activity::Right, [options, flow]]
  end

  # second task
  Uuid = ->((options, flow), **o) do
    options["a"]             = options["a"] + options["model.a"] # rename to uuid.a
    options["uuid.nonsense"] = false                             # filter me out

    [Activity::Right, [options, flow]]
  end

  let (:activity) do
    Activity.build do
      task Model
      task Uuid
    end
  end

  describe "input/output" do

    it do
      model_input  = ->(options) { { "a"       => options["a"]+1 } }
      model_output = ->(options) { { "model.a" => options["a"] } }
      uuid_input   = ->(options) { { "a"       => options["a"]*3, "model.a" => options["model.a"] } }
      uuid_output  = ->(options) { { "uuid.a"  => options["a"] } }

      runtime = Hash.new([])

      # add filters around Model.
      runtime[ Model ] = Activity::Magnetic::Builder::Path.plan do
        task Activity::Wrap::Input.new( model_input ),   id: "task_wrap.input", before: "task_wrap.call_task"
        task Activity::Wrap::Output.new( model_output ), id: "task_wrap.output", before: "End.success", group: :end
      end

      # add filters around Uuid.
      runtime[ Uuid ] = Activity::Magnetic::Builder::Path.plan do
        task Activity::Wrap::Input.new( uuid_input ),   id: "task_wrap.input", before: "task_wrap.call_task"
        task Activity::Wrap::Output.new( uuid_output ), id: "task_wrap.output", before: "End.success", group: :end
      end

      signal, (options, flow_options) = activity.(
      [
        options = { "a" => 1 },
        {},
      ],

      wrap_runtime: runtime, # dynamic additions from the outside (e.g. tracing), also per task.
      runner: Activity::Wrap::Runner,
      wrap_static: Hash.new( Activity::Wrap.initial_activity ), # per activity?
    )

    signal.must_equal activity.outputs[:success].signal
    options.must_equal({"a"=>1, "model.a"=>4, "uuid.a" => 7 })
    end
  end
end
