class AddReservedToPostAuthor < ActiveRecord::Migration[8.1]
  def change
    add_column :post_authors, :reserved, :boolean, default: false, null: false
    add_column :reply_drafts, :reserved, :boolean, default: false, null: false
  end
end
