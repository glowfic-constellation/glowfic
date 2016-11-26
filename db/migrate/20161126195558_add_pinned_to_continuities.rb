class AddPinnedToContinuities < ActiveRecord::Migration
  def change
    add_column :boards, :pinned, :boolean, default: false
  end
end
