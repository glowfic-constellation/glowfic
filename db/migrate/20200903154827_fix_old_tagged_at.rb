class FixOldTaggedAt < ActiveRecord::Migration[5.2]
  def change
    posts = Post.joins(:last_reply).where.not(status: :completed).where.not(last_reply_id: nil).where.not('posts.tagged_at = replies.updated_at')
    posts.update_all('posts.tagged_at = replies.updated_at')
  end
end
