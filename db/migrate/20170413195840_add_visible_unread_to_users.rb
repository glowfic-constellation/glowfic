class AddVisibleUnreadToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :visible_unread, :boolean, default: false
  end
end
