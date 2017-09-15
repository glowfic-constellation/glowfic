class RemoveNotNullFromContent < ActiveRecord::Migration[4.2]
  def change
    change_column :posts, :content, :text, null: true
    change_column :replies, :content, :text, null: true
  end
end
