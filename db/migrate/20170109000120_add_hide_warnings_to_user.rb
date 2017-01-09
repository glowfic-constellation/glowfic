class AddHideWarningsToUser < ActiveRecord::Migration
  def change
    add_column :users, :hide_warnings, :boolean, default: false
  end
end
