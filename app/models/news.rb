# frozen_string_literal: true
class News < ApplicationRecord
  belongs_to :user, inverse_of: :news, optional: false

  validates :content, presence: true

  after_create_commit :invalidate_caches

  def editable_by?(user)
    return false unless user
    return true if user.id == user_id
    user.has_permission?(:edit_news)
  end

  def deletable_by?(user)
    return false unless user
    return true if user.id == user_id
    user.has_permission?(:delete_news)
  end

  def mark_read(user)
    view = NewsView.where(user_id: user.id).first_or_initialize

    if view.new_record?
      view.news = self
      return view.save
    end

    return true if view.news_id > self.id
    view.update!(news: self)
  end

  def self.num_unread_for(user)
    return 0 unless user

    Rails.cache.fetch(NewsView.cache_string_for(user.id), expires_in: 1.day) do
      view = NewsView.find_by(user: user)
      view ? News.where('id > ?', view.news_id).count : News.count
    end
  end

  private

  def invalidate_caches
    NewsView.invalidate_all_caches
  end
end
