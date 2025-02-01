# frozen_string_literal: true
class PostTag < ApplicationRecord
  belongs_to :post, inverse_of: :post_tags, optional: false
  belongs_to :tag, inverse_of: :post_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :setting, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
  belongs_to :content_warning, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
  belongs_to :label, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
  belongs_to :access_circle, foreign_key: :tag_id, inverse_of: :post_tags, optional: true

  validates :post, uniqueness: { scope: :tag }

  after_commit :invalidate_caches, on: [:create, :destroy]

  private

  def invalidate_caches
    return if access_circle.nil?
    access_circle.user_ids.each { |user_id| Rails.cache.delete(PostViewer.cache_string_for(user_id)) }
  end
end
