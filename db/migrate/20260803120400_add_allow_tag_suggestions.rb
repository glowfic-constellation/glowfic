# frozen_string_literal: true
class AddAllowTagSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :allow_tag_suggestions, :boolean, default: true, null: false
    add_column :users, :allow_tag_suggestions, :boolean, default: true, null: false
  end
end
