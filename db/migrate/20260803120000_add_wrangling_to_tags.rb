# frozen_string_literal: true
class AddWranglingToTags < ActiveRecord::Migration[8.0]
  def change
    change_table :tags, bulk: true do |t|
      t.column :canonical, :boolean, default: false, null: false
      t.column :unwrangleable, :boolean, default: false, null: false
      t.column :merger_id, :integer, null: true
    end

    add_index :tags, :merger_id
    add_index :tags, [:type, :canonical]
    add_foreign_key :tags, :tags, column: :merger_id
  end
end
