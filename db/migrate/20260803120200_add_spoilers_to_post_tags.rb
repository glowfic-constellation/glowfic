class AddSpoilersToPostTags < ActiveRecord::Migration[8.1]
  def change
    change_table :post_tags, bulk: true do |t|
      t.boolean :spoiler, default: false, null: false
      t.integer :applies_from_reply_order
    end
    add_index :post_tags, [:tag_id, :post_id], where: "spoiler = false", name: "index_post_tags_unspoilered"

    add_column :users, :reveal_spoiler_tags, :boolean, default: false, null: false
  end
end
