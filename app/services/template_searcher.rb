class TemplateSearcher < Object
  def initialize
  end

  def search(page: 1)
    Template.paginate(page: page, per_page: 2)
  end
end
