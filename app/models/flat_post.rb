# frozen_string_literal: true
class FlatPost < ApplicationRecord
  belongs_to :post, inverse_of: :flat_post, optional: false

  validates :post, uniqueness: true

  # Returns the rendered reply HTML, sourced from S3 when the flat post was
  # generated via the streaming path and from the legacy `content` column
  # otherwise. Returns nil when no flat content has been generated yet.
  def body
    return content if content.present?
    return nil if s3_key.blank?
    S3_BUCKET.object(s3_key).get.body.read
  end

  def self.regenerate_all(before=nil, override=true)
    # uses Post instead of FlatPost in case any are missing
    Post.includes(:flat_post).find_each do |post|
      unless post.flat_post
        # ignore arguments because posts should always have a flat post object and this is Bad
        GenerateFlatPostJob.enqueue(post.id)
        next
      end

      next if before.present? && post.flat_post.updated_at >= before
      next if !override && post.flat_post.updated_at >= post.tagged_at
      GenerateFlatPostJob.enqueue(post.id)
    end
  end
end
