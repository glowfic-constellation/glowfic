# frozen_string_literal: true
class BookmarkPresenter
  attr_reader :bookmark

  def initialize(bookmark)
    @bookmark = bookmark
  end

  def as_json(options={})
    bookmark.as_json_without_presenter({ only: [:id, :user_id, :reply_id, :post_id, :type, :name] }.reverse_merge(options))
  end
end
