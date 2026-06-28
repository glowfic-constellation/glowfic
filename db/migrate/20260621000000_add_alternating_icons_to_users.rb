class AddAlternatingIconsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :alternating_icons, :boolean, default: false
  end
end
