class AddSkinReferences < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      # A user's active personal skin, applied to their own browsing site-wide.
      t.integer :skin_id
      # Reader opt-out of post-recommended skins.
      t.boolean :hide_skins, default: false
      t.index :skin_id
    end

    # A post's recommended skin, shown to readers who have not opted out.
    add_column :posts, :skin_id, :integer
    add_index :posts, :skin_id
  end
end
