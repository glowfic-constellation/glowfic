# frozen_string_literal: true
class IndexPresenter
  attr_reader :index

  def initialize(index)
    @index = index
  end

  def as_json(_options={})
    index_json = index.as_json_without_presenter(only: [:id, :name, :description, :privacy, :authors_locked])
    index_json.merge(user: index.user)
  end
end
