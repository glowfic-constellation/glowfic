class AddCharacterPostIndexToReplies < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # "Which posts use this character" (characters#show and #replace, templates#show, Character#...) runs
  # SELECT DISTINCT post_id FROM replies WHERE character_id ...; with post_id in the index that is an index-only
  # scan instead of reading every matching reply row from the heap. The new index serves every lookup the
  # character_id-only index did, so that one goes.
  def change
    add_index :replies, [:character_id, :post_id], algorithm: :concurrently
    remove_index :replies, column: :character_id, algorithm: :concurrently
  end
end
