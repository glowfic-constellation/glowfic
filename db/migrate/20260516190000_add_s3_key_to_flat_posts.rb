class AddS3KeyToFlatPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :flat_posts, :s3_key, :string
  end
end
