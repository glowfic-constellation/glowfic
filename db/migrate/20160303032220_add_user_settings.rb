class AddUserSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :timezone, :string
  end
end
