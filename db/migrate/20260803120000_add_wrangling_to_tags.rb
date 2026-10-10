class AddWranglingToTags < ActiveRecord::Migration[8.1]
  def change
    change_table :tags, bulk: true do |t|
      t.boolean :canonical, default: false, null: false
      t.boolean :unwrangleable, default: false, null: false
      t.integer :merger_id
    end
    add_index :tags, :merger_id
    add_index :tags, [:type, :canonical]
    add_foreign_key :tags, :tags, column: :merger_id

    change_column_null :tag_tags, :suggested, false, false
  end
end
