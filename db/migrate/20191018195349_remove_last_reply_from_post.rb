class RemoveLastReplyFromPost < ActiveRecord::Migration[5.2]
  def up
    remove_column :posts, :last_reply_id, :int
    remove_column :posts, :last_user_id, :int
    remove_column :posts, :tagged_at, :datetime
  end

  def down
    add_column :posts, :last_reply_id, :int
    add_column :posts, :last_user_id, :int
    add_column :posts, :tagged_at, :datetime
    add_index :posts, :tagged_at

    ActiveRecord::Base.record_timestamps = false
    begin
      Post.for_each do |post|
        tagged_at = [post.created_at, post.replies.map(&:created_at)].flatten.max
        post.tagged_at = tagged_at
        if (last_reply = post.replies.ordered.last)
          post.last_reply_id = last_reply.id
          post.last_user_id = last_reply.user_id
        else
          post.last_user_id = post.user_id
        end

        post.skip_edited = true
        post.save_without_auditing
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end
end
