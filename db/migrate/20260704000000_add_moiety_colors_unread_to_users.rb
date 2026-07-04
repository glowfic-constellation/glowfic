class AddMoietyColorsUnreadToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :moiety_colors_unread, :boolean, default: false
  end
end
