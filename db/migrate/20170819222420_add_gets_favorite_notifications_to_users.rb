class AddGetsFavoriteNotificationsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :favorite_notifications, :boolean, default: true
  end
end
