class CreateTags < ActiveRecord::Migration[4.2]
  def change
    create_table :tags do |t|
      t.integer :user_id, null: false
      t.string :name, null: false
      t.timestamps null: true
    end
    add_index :tags, :name

    create_table :post_tags do |t|
      t.integer :post_id, null: false
      t.integer :tag_id, null: false
      t.boolean :suggested, default: false
      t.timestamps null: true
    end
    add_index :post_tags, :post_id
    add_index :post_tags, :tag_id
  end
end
