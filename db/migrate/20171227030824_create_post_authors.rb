class CreatePostAuthors < ActiveRecord::Migration[5.0]
  def up
    create_table :post_authors do |t|
      t.integer :user_id, null: false
      t.integer :post_id, null: false
      t.timestamps null: true
      t.boolean :can_owe, default: true
      t.boolean :joined, default: false
      t.datetime :invited_at, null: true
      t.integer :invited_by_id, null: true
      t.datetime :joined_at, null: true
    end
    add_index :post_authors, :post_id
    add_index :post_authors, :user_id

    Post.select('posts.*').with_author_ids.find_each do |post|
      first_items = Reply.where(id: Reply.select('MIN(id)').where(post_id: post.id).group(:user_id)).index_by(&:user_id)
      first_items[post.user_id] = post

      post.author_ids.each do |author_id|
        first_item = first_items[author_id]
        PostAuthor.create!(post_id: post.id, user_id: author_id, can_owe: true, joined: true, joined_at: first_item.created_at)
      end
    end
  end
  def down
    drop_table :post_authors
  end
end
