# frozen_string_literal: true
class ReportView < ApplicationRecord
  belongs_to :user, optional: false

  validates :user, uniqueness: true

  after_commit :invalidate_caches

  CACHE_VERSION = 2

  def self.cache_string_for(user_id)
    "#{Rails.env}.#{CACHE_VERSION}.reports_last_read_date.#{user_id}"
  end

  private

  def invalidate_caches
    Rails.cache.delete(ReportView.cache_string_for(user.id))
  end
end
