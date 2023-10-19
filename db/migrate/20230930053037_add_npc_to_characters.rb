class AddNpcToCharacters < ActiveRecord::Migration[6.1]
  def change
    add_column :characters, :npc, :boolean, default: false, null: false
  end
end
