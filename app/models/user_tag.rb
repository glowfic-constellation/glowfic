# frozen_string_literal: true
class UserTag < ApplicationRecord
  belongs_to :user, inverse_of: :user_tags, optional: false
  belongs_to :tag, inverse_of: :user_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :content_warning, foreign_key: :tag_id, inverse_of: :user_tags, optional: true
  belongs_to :access_circle, foreign_key: :tag_id, inverse_of: :user_tags, optional: true

  validates :user, uniqueness: { scope: :tag }

  after_commit :invalidate_cache, on: [:create, :destroy]

  private

  def invalidate_cache
    Rails.cache.delete(PostViewer.cache_string_for(user_id))
  end
end
end
