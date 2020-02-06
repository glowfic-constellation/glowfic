class FlatPost < ApplicationRecord
  belongs_to :post, inverse_of: :flat_posts, optional: false

  validates :post, uniqueness: { scope: :order }
  validates :order, presence: true

  def self.regenerate_all(before=nil, override=true)
    # uses Post instead of FlatPost in case any are missing
    Post.includes(:flat_posts).find_each do |post|
      unless post.flat_posts
        # ignore arguments because posts should always have a flat post object and this is Bad
        GenerateFlatPostJob.enqueue(post.id)
        next
      end

      next if before.present? && post.flat_posts.maximum(:updated_at) >= before
      next if !override && post.flat_posts.maximum(:updated_at) >= post.tagged_at
      GenerateFlatPostJob.enqueue(post.id)
    end
  end
end
