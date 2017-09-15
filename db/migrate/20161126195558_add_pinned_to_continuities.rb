class AddPinnedToContinuities < ActiveRecord::Migration[4.2]
  def change
    add_column :boards, :pinned, :boolean, default: false
  end
end
