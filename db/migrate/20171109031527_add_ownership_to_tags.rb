class AddOwnershipToTags < ActiveRecord::Migration[5.0]
  def change
    add_column :tags, :owned, :boolean, default: false
  end
end
