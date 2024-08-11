# frozen_string_literal: true
class IconPresenter
  attr_reader :icon

  def initialize(icon)
    @icon = icon
  end

  def as_json(options={})
    icon.as_json_without_presenter({ only: [:id, :url, :keyword] }.reverse_merge(options))
  end
end
