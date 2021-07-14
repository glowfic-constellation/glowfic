class Generic::Service < Object
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  extend ActiveModel::Validations

  attr_reader :errors, :model
  attr_accessor :name

  def initialize
    @errors = ActiveModel::Errors.new(self)
  end
end
