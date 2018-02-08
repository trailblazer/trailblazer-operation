module Trailblazer
  class Operation
    # Use {Callable} if you have an operation or any other callable object that does
    # _not_ expose an {Activity interface}. For example, {Operation.call} isn't compatible
    # with activities, hence you need to decorate it using {Callable}. The returned object
    # exposes an {Activity interface}.
    #
    # @param :call [Symbol] Method name to call
    # @param options [Hash] Hash to merge into {circuit_options}, e.g. {:start_task}.
    #
    # @example Create and use a Callable instance.
    #   callable = Trailblazer::Operation::Callable( Memo::Create, call: :__call__ )
    #   callable.( [ctx, {}] ) #=> Activity interface, ::call will invoke Memo::Create.__call__.
    def self.Callable(*args)
      Callable.new(*args)
    end

    # Subprocess allows to have tasks with a different call interface and start event.
    # @param activity any object with an {Activity interface}
    class Callable
      include Activity::Interface

      def initialize(activity, call: :call, **options)
        @activity = activity
        @options  = options
        @call     = call
      end

      def call(args, **circuit_options)
        @activity.public_send(@call, args, circuit_options.merge(@options))
      end

      extend Forwardable
      # @private
      def_delegators :@activity, :to_h, :debug

      def to_s
        %{#<Trailblazer::Activity::Callable activity=#{@activity}>}
      end
    end
  end
end
