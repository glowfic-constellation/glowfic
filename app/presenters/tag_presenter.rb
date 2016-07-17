class TagPresenter
  def initialize(tag)
    @tag = tag
  end

  def as_json(*args, **kwargs)
    return {} unless @tag
    { id: @tag.id,
      name: @tag.name }
  end
end
