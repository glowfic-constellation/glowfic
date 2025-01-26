class AddDefaultHideReplyButtons < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :default_hide_edit_delete_buttons, :boolean, default: false
    add_column :users, :default_hide_add_bookmark_button, :boolean, default: false
  end
end
