class AddUserSettingTimeDisplay < ActiveRecord::Migration
  def change
    add_column :users, :time_display, :string, default: "%b %d, %Y %l:%M %p"
  end
end
