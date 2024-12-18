class AddProfileToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :profile, :string
    add_column :users, :profile_editor_mode, :string, default: 'html'
  end
end
