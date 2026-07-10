# frozen_string_literal: true
class FlatPost < ApplicationRecord
  belongs_to :post, inverse_of: :flat_post, optional: false

  validates :post, uniqueness: true

  def self.regenerate_all(before=nil, override=false)
    if override
      Post.pluck(:id).each { GenerateFlatPostJob.enqueue(it) } # this will make prod sad
    else
      ids = Post.where.missing(:flat_post).pluck(posts: :id)
      ids += FlatPost.joins(:post).where('posts.tagged_at > flat_posts.updated_at').pluck(:post_id)
      ids += FlatPost.where(updated_at: ..before).pluck(:post_id) if before.present?
      ids.each { GenerateFlatPostJob.enqueue(it) }
    end
  end
end
