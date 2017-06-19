class DropGalleryCoverIcon < ActiveRecord::Migration
  def change
    remove_column :galleries, :cover_icon_id
  end
end
