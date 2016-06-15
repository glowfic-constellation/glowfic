class RemoveNotNullFromContent < ActiveRecord::Migration
  def change
    change_column :posts, :content, :text, null: true
    change_column :replies, :content, :text, null: true
  end
end
