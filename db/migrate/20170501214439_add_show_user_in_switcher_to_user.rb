class AddShowUserInSwitcherToUser < ActiveRecord::Migration
  def change
    add_column :users, :show_user_in_switcher, :boolean, default: true
  end
end
