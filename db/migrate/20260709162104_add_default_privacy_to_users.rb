class AddDefaultPrivacyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :default_privacy, :integer, default: 0, null: false
  end
end
