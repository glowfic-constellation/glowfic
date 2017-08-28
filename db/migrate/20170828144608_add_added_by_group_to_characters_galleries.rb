class AddAddedByGroupToCharactersGalleries < ActiveRecord::Migration
  def change
    add_column :characters_galleries, :added_by_group, :boolean, default: false
  end
end
