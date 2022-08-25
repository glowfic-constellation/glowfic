class NewsView < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :news, optional: false

  validates :user, uniqueness: { scope: :news }

  after_commit :invalidate_caches

  CACHE_VERSION = 2

  def self.cache_string_for(user_id)
    "#{Rails.env}.#{CACHE_VERSION}.unread_news_count.#{user_id}"
  end

  def self.invalidate_all_caches
    Rails.cache.delete_matched("#{Rails.env}.#{NewsView::CACHE_VERSION}.unread_news_count.*")
  end

  private

  def invalidate_caches
    Rails.cache.delete(NewsView.cache_string_for(user.id))
  end
end
