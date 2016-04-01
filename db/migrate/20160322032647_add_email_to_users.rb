class AddEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email, :string
    add_column :users, :email_notifications, :boolean
    add_index :users, :email, unique: true
  end
end
