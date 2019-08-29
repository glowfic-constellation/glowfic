class SplitPostTextIntoReplies < ActiveRecord::Migration[5.1]
  def up
    execute <<~SQL
      UPDATE replies
      SET reply_order = reply_order + 1;
    SQL

    Post.find_each do |post|
      reply = Reply.create!(
        post_id: post.id,
        user_id: post.user_id,
        character_id: post.character_id,
        character_alias_id: post.character_alias_id,
        icon_id: post.icon_id,
        content: post.content,
        created_at: post.created_at,
        updated_at: post.updated_at,
        skip_post_update: true
      )
      reply.update_columns(reply_order: 0, created_at: post.created_at, updated_at: post.edited_at)
    end
    Post.auditing_enabled = false
    change_table :posts do |t|
      t.remove :character_id, :character_alias_id, :icon_id, :content
    end
    Post.auditing_enabled = true
  end

  def down
    change_table :posts do |t|
      t.integer :character_id
      t.integer :character_alias_id
      t.integer :icon_id
      t.text :content
    end
    Post.find_each do |post|
      reply = post.replies.find_by(reply_order: 0)
      if post.user_id == reply.user_id
        post.character_id = reply.character_id
        post.character_alias_id = reply.character_alias_id
        post.icon_id = reply.icon_id
        post.content = reply.content
        post.without_auditing { post.save! }
      else
        raise "Post user does not match initial reply's user"
      end
      reply.delete
    end

    execute <<~SQL
      UPDATE replies
      SET reply_order = reply_order - 1;
    SQL
    
    add_index :posts, :character_id
    add_index :posts, :icon_id
    execute "CREATE INDEX idx_fts_post_content ON posts USING gin(to_tsvector('english', coalesce(\"posts\".\"content\"::text, '')))"
  end
end
