class Trailblazer::Operation
  module PublicCall
    # This is the outer-most public `call` method that gets invoked when calling `Create.()`.
    # The signature of this is `params, options, *containers`. This was a mistake, as the
    # first argument could be part of `options` in the first place.
    #
    # Create.(params, runtime_data, *containers)
    #   #=> Result<skills...>
    #
    # In workflows/Nested compositions, this method is not used anymore and it might probably
    # get removed in future versions of TRB.
    #
    # @returns Operation::Result binary result object
    def call(params={}, options={}, *containers)
      options = options.merge("params" => params) # options will be passed to all steps/activities.

      # generate the skill hash that embraces runtime options plus potential containers, the so called Runtime options.
      # This wrapping is supposed to happen once in the entire system.
      skills = Trailblazer::Skill.new(options, *containers) # Runtime options, immutable.

      direction, options, flow_options = super(skills) # DISCUSS: this could be ::call_with_skills.

      # Result is successful if the activity ended with the "right" End event.
      Railway::Result(direction, options)
    end
  end
end


