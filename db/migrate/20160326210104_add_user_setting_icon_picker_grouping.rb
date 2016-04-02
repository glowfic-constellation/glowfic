class AddUserSettingIconPickerGrouping < ActiveRecord::Migration
  def change
    add_column :users, :icon_picker_grouping, :boolean, default: true
  end
end
