class TemplateSearcher < Object
  def initialize
  end

  def search(page: 1)
    Template.paginate(page: page)
  end
end
