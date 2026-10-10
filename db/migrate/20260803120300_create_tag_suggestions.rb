class CreateTagSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :tag_suggestions do |t|
      t.integer :post_id, null: false
      t.integer :user_id, null: false
      t.integer :tag_id
      t.string :tag_type
      t.citext :tag_name
      t.integer :status, default: 0, null: false
      t.integer :resolved_by_id
      t.datetime :resolved_at
      t.text :note
      t.boolean :spoiler, default: false, null: false
      t.integer :applies_from_reply_order
      t.timestamps
    end
    add_index :tag_suggestions, [:post_id, :status]
    add_index :tag_suggestions, :user_id
    # A suggestion names either an existing tag or a proposed one, and is unique
    # per post either way, whoever suggested it.
    add_index :tag_suggestions, [:post_id, :tag_id], unique: true, where: "tag_id IS NOT NULL",
      name: "index_tag_suggestions_on_post_and_tag"
    add_index :tag_suggestions, [:post_id, :tag_type, :tag_name], unique: true, where: "tag_id IS NULL",
      name: "index_tag_suggestions_on_post_and_name"
    add_foreign_key :tag_suggestions, :posts
    add_foreign_key :tag_suggestions, :users
    add_foreign_key :tag_suggestions, :users, column: :resolved_by_id
    add_foreign_key :tag_suggestions, :tags

    add_column :posts, :allow_tag_suggestions, :boolean, default: true, null: false
    add_column :users, :allow_tag_suggestions, :boolean, default: true, null: false
  end
end
