class AddVisibleUnreadToUsers < ActiveRecord::Migration
  def change
    add_column :users, :visible_unread, :boolean, default: false
  end
end
