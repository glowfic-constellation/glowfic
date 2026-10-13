class AddGroupToCharacters < ActiveRecord::Migration[4.2]
  def change
    create_table :character_groups do |t|
      t.integer :user_id, null: false
      t.string :name, null: false
    end
    add_column :characters, :character_group_id, :integer
    add_index :characters, :character_group_id
  end
end
