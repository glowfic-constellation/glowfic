class AddDefaultHideRetiredCharactersToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :default_hide_retired_characters, :boolean, default: false
  end
end
