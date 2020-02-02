class RemoveReplyIndexFromReplies < ActiveRecord::Migration[5.2]
  # cannot change indexes concurrently inside transactions
  self.disable_ddl_transaction!

  def change
    remove_index :replies, column: :reply_order, algorithm: :concurrently
  end
end
