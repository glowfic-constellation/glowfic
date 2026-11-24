class AddCharacterCreatedIndexToReplies < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Reply search by character (Reply::Searcher, newest first) walks index_replies_on_created_at filtering on
  # character_id, which reads every newer reply for a character that hasn't posted lately, or sorts all of a busy
  # character's replies on deep pages. This index returns a character's replies already in date order.
  def change
    add_index :replies, [:character_id, :created_at], algorithm: :concurrently
  end
end
