class AddScheduledAtToReplyDrafts < ActiveRecord::Migration[8.0]
  def change
    add_column :reply_drafts, :scheduled_at, :datetime
    add_index :reply_drafts, :scheduled_at
  end
end
