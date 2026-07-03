class AddMegaToBoard < ActiveRecord::Migration[8.0]
  def change
    add_column :boards, :mega, :boolean, default: false
  end
end
