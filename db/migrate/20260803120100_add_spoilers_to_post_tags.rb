# frozen_string_literal: true
class AddSpoilersToPostTags < ActiveRecord::Migration[8.0]
  def change
    change_table :post_tags, bulk: true do |t|
      t.column :spoiler, :boolean, default: false, null: false
      t.column :reveal_after_reply_order, :integer, null: true
    end

    add_index :post_tags, [:tag_id, :post_id], where: "spoiler = false", name: "index_post_tags_unspoilered"
  end
end
