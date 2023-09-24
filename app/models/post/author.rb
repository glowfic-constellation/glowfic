class Post::Author < ApplicationRecord
  belongs_to :post, optional: false
  belongs_to :user, optional: false

  validates :user, uniqueness: { scope: :post }
  validate :valid_coauthor

  after_commit :invalidate_caches, on: [:create, :destroy]

  def invalidate_caches
    self.class.clear_cache_for(user)
  end

  def self.clear_cache_for(authors)
    blocked_ids = Block.where(blocking_user: authors, hide_me: [:posts, :all]).pluck(:blocked_user_id)
    blocked_ids.each { |blocked| Rails.cache.delete(Block.cache_string_for(blocked, 'blocked')) }
    hiding_ids = Block.where(blocked_user: authors, hide_them: [:posts, :all]).pluck(:blocking_user_id)
    hiding_ids.each { |blocker| Rails.cache.delete(Block.cache_string_for(blocker, 'hidden')) }
  end

  def valid_coauthor
    return if persisted?

    blocked_ids = user.user_ids_uninteractable
    return if blocked_ids.empty?

    post.authors.reset # clear association cache
    all_author_ids = (post.author_ids + [post.user_id]).uniq

    return unless all_author_ids.intersect?(blocked_ids)
    errors.add(:user, "cannot be added to post")
  end
end
