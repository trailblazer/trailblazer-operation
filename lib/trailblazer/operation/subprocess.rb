module Trailblazer
  class Activity < Module    # A {Subprocess} is an instance of an abstract {Activity} that can be `call`ed.
     # It is the runtime instance that runs from a specific start event.
    def self.Subprocess(*args)
      Subprocess.new(*args)
    end

    # Subprocess allows to have tasks with a different call interface and start event.
    # @param activity any object with an {Activity interface}
    class Subprocess
      include Interface

      def initialize(activity, call: :call, **options)
        @activity = activity
        @options  = options
        @call     = call
      end

      def call(args, **circuit_options)
        @activity.public_send(@call, args, circuit_options.merge(@options))
      end

      # @private
      def to_h
        @activity.to_h # TODO: test explicitly
      end

      def debug
        @activity.debug
      end

      def to_s
        %{#<Trailblazer::Activity::Subprocess activity=#{@activity}>}
      end
    end
  end
end

# circuit.( args, runner: Runner, start_at: raise, **circuit_flow_options )

# subprocess.( options, flow_options, *args, start_event:<Event>, last_signal: signal )
