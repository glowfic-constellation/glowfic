class AddFavoriteIdToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :favorite_id, :integer
  end
end
