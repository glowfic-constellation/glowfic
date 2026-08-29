# frozen_string_literal: true
class CreateWranglingAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :wrangling_assignments do |t|
      t.integer :user_id, null: false
      t.integer :setting_id, null: false

      t.timestamps
    end

    add_index :wrangling_assignments, [:user_id, :setting_id], unique: true
    add_index :wrangling_assignments, :setting_id
    add_foreign_key :wrangling_assignments, :users
    add_foreign_key :wrangling_assignments, :tags, column: :setting_id
  end
end
