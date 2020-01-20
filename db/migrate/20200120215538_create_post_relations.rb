class CreatePostRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :post_relations do |t|
      t.integer :post_id, null: false
      t.integer :related_post_id, null: false
      t.text :relationship, null: false, default: "is related to"
      t.boolean :approved, default: false
      t.timestamps
    end

    add_index :post_relations, :post_id
    add_index :post_relations, :related_post_id
  end
end
