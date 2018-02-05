require "test_helper"

class SubprocessHelper < Minitest::Spec
  Circuit = Trailblazer::Circuit
  Activity = Trailblazer::Activity

  module Blog
    Read    = ->((options, *args), *) { options["Read"] = 1; [ Activity::Right, [options, *args] ] }
    Next    = ->((options, *args), *) { options["NextPage"] = []; [ options["return"], [options, *args] ] }
    Comment = ->((options, *args), *) { options["Comment"] = 2; [ Activity::Right, [options, *args] ] }
  end

  module User
    Relax   = ->((options, *args), *) { options["Relax"]=true; [ Activity::Right, [options, *args] ] }
  end

  ### Subprocess( )
  ###
  describe "circuit with 1 level of nesting" do # TODO: test this kind of configuration in dsl_tests somewhere.
    let(:blog) do
      Module.new do
        extend Activity::Path()

        task task: Blog::Read
        task task: Blog::Next, Output(Activity::Right, :done) => "End.success", Output(Activity::Left, :success) => :success
        task task: Blog::Comment
      end
    end

    let(:user) do
      _blog = blog

      Module.new do
        extend Activity::Path()

        task task: _blog, _blog.outputs[:success] => :success
        task task: User::Relax
      end
    end

    it "ends before comment, on next_page" do
      user.( [options = { "return" => Activity::Right }] ).must_equal(
        [user.outputs[:success].signal, [{"return"=>Trailblazer::Activity::Right, "Read"=>1, "NextPage"=>[], "Relax"=>true}]]
      )

      options.must_equal({"return"=>Trailblazer::Activity::Right, "Read"=>1, "NextPage"=>[], "Relax"=>true})
    end
  end

  ### Subprocess( End1, End2 )
  ###
  describe "circuit with 2 end events in the nested process" do
    let(:blog) do
      Module.new do
        extend Activity::Path()

        task task: Blog::Read
        task task: Blog::Next, Output(Activity::Right, :success___) => :__success, Output(Activity::Left, :retry___) => _retry=End(:retry)
      end
    end

    let(:user) do
      _blog = blog

      Module.new do
        extend Activity::Path()

        task task: _blog, _blog.outputs[:success] => :success, _blog.outputs[:retry] => "End.success"
        task task: User::Relax
      end
    end

    it "runs from Subprocess->default to Relax" do
      user.( [ options = { "return" => Activity::Right } ] ).must_equal [
        user.outputs[:success].signal,
        [ {"return"=>Activity::Right, "Read"=>1, "NextPage"=>[], "Relax"=>true} ]
      ]

      options.must_equal({"return"=>Activity::Right, "Read"=>1, "NextPage"=>[], "Relax"=>true})
    end

    it "runs from other Subprocess end" do
      user.( [ options = { "return" => Activity::Left } ] ).must_equal [
        user.outputs[:success].signal,
        [ {"return"=>Activity::Left, "Read"=>1, "NextPage"=>[]} ]
      ]

      options.must_equal({"return"=>Activity::Left, "Read"=>1, "NextPage"=>[]})
    end

    #---
    #- Subprocess( activity, start_at )
    let(:with_nested_and_start_at) do
      _blog = blog

      Module.new do
        extend Activity::Path()

        task task: Activity::Subprocess( _blog, task: Blog::Next ), _blog.outputs[:success] => :success
        task task: User::Relax
      end
    end

    it "runs Subprocess from alternative start" do
      with_nested_and_start_at.( [options = { "return" => Activity::Right }] ).
        must_equal [
          with_nested_and_start_at.outputs[:success].signal,
          [ {"return"=>Activity::Right, "NextPage"=>[], "Relax"=>true} ]
        ]

      options.must_equal({"return"=>Activity::Right, "NextPage"=>[], "Relax"=>true})
    end

    #---
    #- Subprocess(  activity, call: :__call__ ) { ... }
    describe "Subprocess with :call option" do
      let(:process) do
        class Workout
          def self.__call__((options, *args), *)
            options[:workout]   = 9

            return Activity::Right, [options, *args]
          end
        end

        subprocess = Activity::Subprocess( Workout, call: :__call__ )

        Module.new do
        extend Activity::Path()

          task task: subprocess
          task task: User::Relax
        end
      end

      it "runs Subprocess process with __call__" do
        process.( [options = { "return" => Activity::Right }] ).
          must_equal [
            process.outputs[:success].signal,
            [{"return"=>Activity::Right, :workout=>9, "Relax"=>true}]
          ]

        options.must_equal({"return"=>Activity::Right, :workout=>9, "Relax"=>true})
      end
    end
  end
end
