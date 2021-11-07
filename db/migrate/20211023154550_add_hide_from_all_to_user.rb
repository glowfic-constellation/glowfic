class AddHideFromAllToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :hide_from_all, :boolean, default: false
  end
end
