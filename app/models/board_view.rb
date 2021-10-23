class BoardView < ApplicationRecord
  belongs_to :board, optional: false
  belongs_to :user, optional: false

  validates :board, uniqueness: { scope: :user }

  after_commit :invalidate_cache

  private

  def invalidate_cache
    Rails.cache.delete(Post::View.cache_string_for(user_id))
  end
end
