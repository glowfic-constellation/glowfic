class AddUserSettingTimeDisplay < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :time_display, :string, default: "%b %d, %Y %l:%M %p"
  end
end
