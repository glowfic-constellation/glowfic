class AddSaltToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :salt_uuid, :string
    add_column :users, :unread_opened, :boolean, default: false
  end
end
