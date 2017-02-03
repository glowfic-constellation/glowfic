class AddHideHiatusedTagsOwedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :hide_hiatused_tags_owed, :boolean, :default => false
  end
end
