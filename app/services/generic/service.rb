class Generic::Service < Object
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  extend ActiveModel::Validations

  attr_reader :model
end
