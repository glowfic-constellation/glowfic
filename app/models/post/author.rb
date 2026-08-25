# frozen_string_literal: true
class Post::Author < ApplicationRecord
  belongs_to :post, optional: false
  belongs_to :user, optional: false

  validates :user, uniqueness: { scope: :post }

  after_commit :invalidate_caches, on: [:create, :destroy]

  # authors whose in-progress statuses are visible to their coauthors, either
  # because of a per-post override or because of their site-wide default
  scope :showing_drafts, -> {
    joins(:user).where('post_authors.show_drafts IS TRUE OR (post_authors.show_drafts IS NULL AND users.show_drafts_to_coauthors IS TRUE)')
  }

  # nil show_drafts means the author has not set a preference for this post, so
  # their site-wide default applies
  def shows_drafts?
    return show_drafts unless show_drafts.nil?
    !!user.show_drafts_to_coauthors
  end

  def invalidate_caches
    self.class.clear_cache_for(user)
  end

  def self.clear_cache_for(authors)
    blocked_ids = Block.where(blocking_user: authors, hide_me: [:posts, :all]).pluck(:blocked_user_id)
    blocked_ids.each { |blocked| Rails.cache.delete(Block.cache_string_for(blocked, 'blocked')) }
    hiding_ids = Block.where(blocked_user: authors, hide_them: [:posts, :all]).pluck(:blocking_user_id)
    hiding_ids.each { |blocker| Rails.cache.delete(Block.cache_string_for(blocker, 'hidden')) }
  end
end
