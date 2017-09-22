class AddSetting < ActiveRecord::Migration[4.2]
  def change
    add_column :characters, :setting, :string
    remove_column :icons, :attribution
  end
end
