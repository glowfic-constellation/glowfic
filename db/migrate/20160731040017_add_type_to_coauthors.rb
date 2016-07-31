class AddTypeToCoauthors < ActiveRecord::Migration
  def change
    add_column :board_authors, :cameo, :boolean, default: false
  end
end
