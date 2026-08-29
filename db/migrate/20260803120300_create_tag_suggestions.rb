# frozen_string_literal: true
class CreateTagSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :tag_suggestions do |t|
      t.integer :post_id, null: false
      t.integer :user_id, null: false
      t.integer :tag_id, null: true
      t.string :tag_type, null: true
      t.citext :tag_name, null: true
      t.integer :status, null: false, default: 0
      t.integer :resolved_by_id, null: true
      t.datetime :resolved_at, null: true
      t.text :note, null: true
      t.boolean :spoiler, null: false, default: false
      t.integer :reveal_after_reply_order, null: true

      t.timestamps
    end

    add_index :tag_suggestions, [:post_id, :status]
    add_index :tag_suggestions, :user_id

    # Keyed on the post and tag, never the suggester. Two partial indexes: a
    # suggestion names either an existing tag or a proposed name, never both.
    add_index :tag_suggestions, [:post_id, :tag_id],
      unique: true, where: "tag_id IS NOT NULL", name: "index_tag_suggestions_on_post_and_tag"
    add_index :tag_suggestions, [:post_id, :tag_type, :tag_name],
      unique: true, where: "tag_id IS NULL", name: "index_tag_suggestions_on_post_and_name"

    add_foreign_key :tag_suggestions, :posts
    add_foreign_key :tag_suggestions, :users
    add_foreign_key :tag_suggestions, :tags
    add_foreign_key :tag_suggestions, :users, column: :resolved_by_id
  end
end
