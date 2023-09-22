class AddHideFromAllToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :hide_from_all, :boolean
  end
end
