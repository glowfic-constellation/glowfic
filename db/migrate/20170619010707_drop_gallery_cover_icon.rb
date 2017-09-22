class DropGalleryCoverIcon < ActiveRecord::Migration[4.2]
  def change
    remove_column :galleries, :cover_icon_id
  end
end
