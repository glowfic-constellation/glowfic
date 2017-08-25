class AddDefaultCharacterSplitToUsers < ActiveRecord::Migration
  def change
    add_column :users, :default_character_split, :string, default: 'template'
  end
end
