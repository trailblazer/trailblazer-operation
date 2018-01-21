module Trailblazer
  module Operation::Railway
    # Call the user's steps with a differing API (inspired by Maciej Mensfeld) that
    # only receives keyword args. The `options` keyword is the stateful context object
    #
    #   def my_step( params:, ** )
    #   def my_step( params:, options:, ** )
    module Macaroni
      def self.call(user_proc)
        Activity::TaskBuilder::Task.new( Trailblazer::Option.build( Macaroni::Option, user_proc ), user_proc )
      end

      class Option < Trailblazer::Option
        # The Option#call! method prepares the arguments.
        def self.call!(proc, options, *)
          proc.( **options.to_hash.merge( options: options ) )
        end
      end
    end

    KwSignature = Macaroni
  end
end
