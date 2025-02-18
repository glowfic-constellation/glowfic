class CreateTemplateTags < ActiveRecord::Migration[6.0]
  def change
    create_table :template_tags do |t|
      t.integer :template_id, null: false
      t.integer :tag_id, null: false
      t.boolean :primary, default: false
      t.timestamps null: true

      t.index :template_id
      t.index :tag_id
      t.index :primary
    end

    add_column :character_tags, :primary, :boolean
    add_index :character_tags, :primary
  end
end
