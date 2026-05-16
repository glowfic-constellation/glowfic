# frozen_string_literal: true
class FlatPost < ApplicationRecord
  belongs_to :post, inverse_of: :flat_post, optional: false

  validates :post, uniqueness: true

  # Returns the rendered reply HTML, sourced from S3 when the flat post was
  # generated via the streaming path and from the legacy `content` column
  # otherwise. Returns nil when no flat content has been generated yet.
  # Prefer `stream_body_to` for serving to clients — it avoids loading the
  # full body into a Ruby string.
  def body
    return content if content.present?
    return nil if s3_key.blank?
    S3_BUCKET.object(s3_key).get.body.read
  end

  # Writes the rendered reply HTML to `io` (anything responding to #write).
  # For legacy rows this is a single write of the in-memory content string;
  # for S3-backed rows it streams chunks from S3, so peak memory stays at
  # O(chunk_size) regardless of total body size.
  def stream_body_to(io)
    if content.present?
      io.write(content)
    elsif s3_key.present?
      S3_BUCKET.object(s3_key).get { |chunk| io.write(chunk) }
    end
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
