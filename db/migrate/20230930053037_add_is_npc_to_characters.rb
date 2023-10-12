class AddIsNpcToCharacters < ActiveRecord::Migration[6.1]
  def change
    add_column :characters, :is_npc, :boolean, default: false, null: false
  end
end
