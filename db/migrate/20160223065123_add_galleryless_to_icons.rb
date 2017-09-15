class AddGallerylessToIcons < ActiveRecord::Migration[4.2]
  def change
    add_column :icons, :has_gallery, :boolean, default: false
    add_index :icons, :has_gallery
    ids = []
    Icon.all.each do |icon|
      next unless icon.galleries.present?
      ids << icon.id
    end
    Icon.where(id: ids).update_all(has_gallery: true)
  end
end
