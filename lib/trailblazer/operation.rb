require "forwardable"

# trailblazer-context
require "trailblazer/option"
require "trailblazer/context"
require "trailblazer/container_chain"

require "trailblazer/activity"
require "trailblazer/activity/dsl/linear"


module Trailblazer
  # DISCUSS: I don't know where else to put this. It's not part of the {Activity} concept
  class Activity
    class Railway
      module End
        # @private
        class Success < Activity::End; end
        class Failure < Activity::End; end
      end
    end

    module Operation
      def self.OptionsForState()
        {
          end_task: Activity::Railway::End::Success.new(semantic: :success),
          failure_end: Activity::Railway::End::Failure.new(semantic: :failure),
        }
      end
    end
  end

  def self.Operation(options)
    Class.new(Activity::Railway( Activity::Operation.OptionsForState.merge(options) )) do
      extend Operation::PublicCall
    end
  end

  # The Trailblazer-style operation.
  # Note that you don't have to use our "opinionated" version with result object, skills, etc.
  class Operation < Activity::Railway(Activity::Operation.OptionsForState)

    # module FastTrackActivity
      # builder_options = {
      #   track_end:     Railway::End::Success.new(semantic: :success),
      #   failure_end:   Railway::End::Failure.new(semantic: :failure),
      #   pass_fast_end: Railway::End::PassFast.new(semantic: :pass_fast),
      #   fail_fast_end: Railway::End::FailFast.new(semantic: :fail_fast)
      # }

    #   extend Activity::FastTrack(pipeline: Railway::Normalizer::Pipeline, builder_options: builder_options)
    # end

    # extend Skill::Accessors # ::[] and ::[]= # TODO: fade out this usage.


require "trailblazer/operation/public_call"      # TODO: Remove in 3.0.
    extend PublicCall              # ::call(params, { current_user: .. })
    # extend Trace                   # ::trace
  end
end

require "trailblazer/operation/inspect"

require "trailblazer/operation/class_dependencies"
require "trailblazer/operation/deprecated_macro" # TODO: remove in 2.2.

require "trailblazer/operation/result"
require "trailblazer/operation/railway"

require "trailblazer/operation/railway/fast_track"
require "trailblazer/operation/trace"

require "trailblazer/operation/railway/macaroni"
