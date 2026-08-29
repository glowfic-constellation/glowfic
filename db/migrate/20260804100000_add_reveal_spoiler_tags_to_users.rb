# frozen_string_literal: true
class AddRevealSpoilerTagsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :reveal_spoiler_tags, :boolean, default: false, null: false
  end
end
