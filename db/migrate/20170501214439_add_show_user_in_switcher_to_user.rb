class AddShowUserInSwitcherToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :show_user_in_switcher, :boolean, default: true
  end
end
