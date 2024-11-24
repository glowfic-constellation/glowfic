class Tag::UserTag < ApplicationRecord
  self.table_name = 'user_tags'

  belongs_to :user, inverse_of: :user_tags, optional: false
  belongs_to :tag, optional: false
  belongs_to :access_circle, foreign_key: :tag_id, inverse_of: :user_tags, optional: true

  validates :user, uniqueness: { scope: :tag }

  after_commit :invalidate_cache, on: [:create, :destroy]

  private

  def invalidate_cache
    Rails.cache.delete(PostViewer.cache_string_for(user_id))
  end
end
