class AddNotificationsPerPageToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :notifications_per_page, :integer, default: 25
  end
end
