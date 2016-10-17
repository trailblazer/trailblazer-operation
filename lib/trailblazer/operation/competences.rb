# Op::[]
# Op::[]=
# Op#[]
# Op#[]=
# Op.(params, { "constructor" => competences })
module Trailblazer::Operation::Competences
  module ClassMethods
    def competences
      @competences ||= {}
    end

    require "uber/delegates"
    extend Uber::Delegates
    delegates :competences, :[], :[]=
  end

  def self.included(includer)
    includer.extend ClassMethods
  end

  def initialize(params, instance_attrs={})
    # the operation instance will now find runtime-competences first, then classlevel competences.
    require "trailblazer/competences"
    competences = Trailblazer::Competences.new(instance_attrs, self.class.competences)

    super(params, competences)
  end
end
