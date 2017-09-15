class AddUserSettingIconPickerGrouping < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :icon_picker_grouping, :boolean, default: true
  end
end
