class AddMoreUserSettings < ActiveRecord::Migration
  def change
    add_column :users, :layout, :string
    add_column :users, :moiety_name, :string
    add_column :users, :default_view, :string
  end
end
