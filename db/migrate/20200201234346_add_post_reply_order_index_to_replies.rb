class AddPostReplyOrderIndexToReplies < ActiveRecord::Migration[5.2]
  # cannot change indexes concurrently inside transactions
  self.disable_ddl_transaction!

  def change
    add_index :replies, [:post_id, :reply_order], algorithm: :concurrently
  end
end
