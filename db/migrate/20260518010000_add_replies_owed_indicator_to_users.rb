class AddRepliesOwedIndicatorToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :replies_owed_indicator, :boolean, default: false, null: false
  end
end
