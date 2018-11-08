class Generic::Searcher < Object
  extend ActiveModel::Translation
  extend ActiveModel::Validations

  attr_accessor :name
  attr_reader   :errors, :templates, :users

  def initialize(search, templates: [], users: [])
    @search_results = search
    @templates = templates
    @users = users
    @errors = ActiveModel::Errors.new(self)
  end
end
