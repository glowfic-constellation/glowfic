class ChangeBoardsToContinuities < ActiveRecord::Migration[5.2]
  def up
    rename_table :boards, :continuities
    rename_table :board_authors, :continuity_authors
    rename_table :board_views, :continuity_views

    rename_column :continuity_authors, :board_id, :continuity_id
    rename_column :continuity_views, :board_id, :continuity_id

    rename_column :board_sections, :board_id, :continuity_id
    rename_column :posts, :board_id, :continuity_id
  end

  def down
    rename_table :continuities, :boards
    rename_table :continuity_authors, :board_authors
    rename_table :continuity_views, :board_views

    rename_column :board_authors, :continuity_id, :board_id
    rename_column :board_views, :continuity_id, :board_id

    rename_column :board_sections, :continuity_id, :board_id
    rename_column :posts, :continuity_id, :board_id
  end
end
