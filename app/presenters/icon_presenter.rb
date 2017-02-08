class IconPresenter
  attr_reader :icon

  def initialize(icon)
    @icon = icon
  end

  def as_json(options={})
    return {} unless icon
    icon.as_json_without_presenter({only: [:id, :url, :keyword]}.reverse_merge(options))
  end
end
