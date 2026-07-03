class AddSkinApproval < ActiveRecord::Migration[8.0]
  def change
    change_table :skins, bulk: true do |t|
      # Mod approval is pinned to a specific CSS version via approved_digest.
      # When the CSS changes the digest stops matching, so approval lapses until
      # the new version is reviewed again.
      t.datetime :approved_at
      t.integer :approved_by_id
      t.string :approved_digest
      # Cached "needs review" flag (CSS uses something the safe tier strips), so
      # the gallery and review queue can be scoped in SQL.
      t.boolean :dangerous, null: false, default: false
    end
  end
end
