class AddSetting < ActiveRecord::Migration
  def change
    add_column :characters, :setting, :string
    remove_column :icons, :attribution
  end
end
