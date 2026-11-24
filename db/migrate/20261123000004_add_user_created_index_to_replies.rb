class AddUserCreatedIndexToReplies < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Reply search by author (Reply::Searcher, newest first) has the same problem as by character: Postgres walks
  # index_replies_on_created_at filtering on user_id, which reads every newer reply on the site for an author who
  # hasn't posted lately (over 10 s on production for an author last active in 2025). This index returns an
  # author's replies already in date order.
  def change
    add_index :replies, [:user_id, :created_at], algorithm: :concurrently
  end
end
