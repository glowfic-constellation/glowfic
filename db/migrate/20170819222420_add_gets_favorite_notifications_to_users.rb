class AddGetsFavoriteNotificationsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :favorite_notifications, :boolean, default: true
  end
end
