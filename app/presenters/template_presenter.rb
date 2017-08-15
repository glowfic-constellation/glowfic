class TemplatePresenter
  attr_reader :template

  def initialize(template)
    @template = template
  end

  def as_json(options={})
    return {} unless template
    template.as_json_without_presenter({only: [:id, :name]}.reverse_merge(options))
  end
end
