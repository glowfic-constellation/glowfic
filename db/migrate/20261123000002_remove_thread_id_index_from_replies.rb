class RemoveThreadIdIndexFromReplies < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # replies.thread_id dates from the original 2015 schema and nothing reads it (thread_id in app/ is messages only),
  # so its index is pure write and storage cost on the largest table.
  def change
    remove_index :replies, :thread_id, algorithm: :concurrently
  end
end
