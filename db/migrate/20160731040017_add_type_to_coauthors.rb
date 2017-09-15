class AddTypeToCoauthors < ActiveRecord::Migration[4.2]
  def change
    add_column :board_authors, :cameo, :boolean, default: false
  end
end
