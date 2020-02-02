class CleanupReplyOrder < ActiveRecord::Migration[5.2]
  def change
    replies = Reply.where(new_order: nil)
    raise ActiveRecord::Rollback if replies.count > 1000
    replies.update_all('new_order = reply_order + 1')

    remove_column :replies, :reply_order
    rename_column :replies, :new_order, :reply_order
    add_index :replies, :reply_order
  end
end
