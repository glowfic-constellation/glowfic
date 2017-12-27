class CreatePostAuthors < ActiveRecord::Migration[5.0]
  def up
    create_table :post_authors do |t|
      t.integer :user_id, null: false
      t.integer :post_id, null: false
      t.timestamps null: true
      t.boolean :can_owe, default: true
      t.boolean :joined, default: false
      t.datetime :invited_at, null: true
      t.datetime :joined_at, null: true
    end
    add_index :post_authors, :post_id
    add_index :post_authors, :user_id
    Post.with_author_ids.find_each do |post|
      post.author_ids.each do |author_id|
        first_item = if post.user_id == author_id
          post
        else
          post.replies.where(user_id: author_id).order(id: :asc).first
        end
        PostAuthor.create!(post_id: post.id, user_id: author_id, can_owe: true, joined: true, joined_at: first_item.created_at)
      end
    end
  end
  def down
    drop_table :post_authors
  end
end
