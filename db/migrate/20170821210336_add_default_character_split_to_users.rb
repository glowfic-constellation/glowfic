class AddDefaultCharacterSplitToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :default_character_split, :string, default: 'template'
  end
end
