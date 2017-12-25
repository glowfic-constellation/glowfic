class FlatPost < ApplicationRecord
  belongs_to :post, inverse_of: :flat_post, optional: false

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
