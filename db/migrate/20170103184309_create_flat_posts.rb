class CreateFlatPosts < ActiveRecord::Migration
  def up
    create_table :flat_posts do |t|
      t.integer :post_id, :null => false
      t.text :content
      t.timestamps null: true
    end
    add_index :flat_posts, :post_id
    ids = Post.pluck(:id)
    ids.each do |post_id|
      fp = FlatPost.new
      fp.post_id = post_id
      fp.save!
    end
    ids.each do |post_id|
      Resque.enqueue(GenerateFlatPostJob, post_id)
    end
  end

  def down
    drop_table :flat_posts
  end
end
