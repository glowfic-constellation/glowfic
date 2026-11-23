class AddIconPostIndexToReplies < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # "Which posts use this icon" (icons#show and #replace) runs SELECT DISTINCT post_id FROM replies WHERE icon_id = ...,
  # and icons#show counts an icon's replies in visible posts; with post_id in the index both are index-only scans instead
  # of reading every matching reply row from the heap. The new index serves every lookup the icon_id-only index did, so
  # that one goes.
  def change
    add_index :replies, [:icon_id, :post_id], algorithm: :concurrently
    remove_index :replies, column: :icon_id, algorithm: :concurrently
  end
end
