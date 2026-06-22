class AddManualUnreadToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :manual_unread, :boolean, default: false
  end
end
