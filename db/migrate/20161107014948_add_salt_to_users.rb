class AddSaltToUsers < ActiveRecord::Migration
  def change
    add_column :users, :salt_uuid, :string
    add_column :users, :unread_opened, :boolean, default: false
  end
end
