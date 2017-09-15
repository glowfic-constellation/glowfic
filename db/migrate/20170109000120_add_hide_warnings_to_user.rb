class AddHideWarningsToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :hide_warnings, :boolean, default: false
  end
end
