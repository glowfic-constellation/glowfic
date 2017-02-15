class CreateCharacterAliases < ActiveRecord::Migration
  def change
    create_table :character_aliases do |t|
      t.integer :character_id, null: false
      t.string :name, null: false
      t.timestamps
    end
    add_index :character_aliases, :character_id

    add_column :posts, :character_alias_id, :integer
    add_column :replies, :character_alias_id, :integer
    add_column :reply_drafts, :character_alias_id, :integer
  end
end
