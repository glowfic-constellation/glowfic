class RenameBoardToContinuity < ActiveRecord::Migration[5.2]
  def change
  	rename_column :posts, :board_id, :continuity_id
  	rename_column :board_authors, :board_id, :continuity_id
  	rename_column :board_sections, :board_id, :continuity_id
  	rename_column :board_views, :board_id, :continuity_id

  	rename_table :board_authors, :continuity_authors
  	rename_table :board_sections, :subcontinuities
  	rename_table :board_views, :continuity_views
  	rename_table :boards, :continuities
  end
end
