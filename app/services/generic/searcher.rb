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

  private

  def search_templates(template_id)
    template = Template.find_by(id: template_id)
    if template.present?
      if @users.blank? || template.user_id == @users.first.id
        @templates = [template]
        do_search_templates(template)
      else
        errors.add(:base, "The specified author and template do not match; template filter will be ignored.")
        @templates = []
      end
    else
      errors.add(:template, "could not be found.")
      @templates = []
    end
  end
end
