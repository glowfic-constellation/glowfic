class CreateCanon < ActiveRecord::Migration[5.0]
  def change
    create_table :tag_tags do |t|
      t.integer :tagged_id, null: false
      t.integer :tag_id, null: false
      t.boolean :suggested, default: false
      t.timestamps null: true
    end
    add_index :tag_tags, :tagged_id
    add_index :tag_tags, :tag_id
    add_column :tags, :description, :text
  end
end
