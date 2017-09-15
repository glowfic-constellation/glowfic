class AddMoreUserSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :layout, :string
    add_column :users, :moiety_name, :string
    add_column :users, :default_view, :string
  end
end
