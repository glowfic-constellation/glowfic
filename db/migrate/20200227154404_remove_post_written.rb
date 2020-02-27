class SplitPostTextIntoReplies < ActiveRecord::Migration[5.1]
  def up
    Post.auditing_enabled = false
    change_table :posts do |t|
      t.remove :character_id
      t.remove :character_alias_id
      t.remove :icon_id
      t.remove :content
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
      reply = post.written
      if post.user_id == reply.user_id
        post.character_id = reply.character_id
        post.character_alias_id = reply.character_alias_id
        post.icon_id = reply.icon_id
        post.content = reply.content
        post.without_auditing { post.save! }
      else
        raise "Post user does not match initial reply's user"
      end
    end

    add_index :posts, :character_id
    add_index :posts, :icon_id
    execute "CREATE INDEX idx_fts_post_content ON posts USING gin(to_tsvector('english', coalesce(\"posts\".\"content\"::text, '')))"
  end
end
