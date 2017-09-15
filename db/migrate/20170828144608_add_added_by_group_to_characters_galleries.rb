class AddAddedByGroupToCharactersGalleries < ActiveRecord::Migration[4.2]
  def change
    add_column :characters_galleries, :added_by_group, :boolean, default: false
  end
end
