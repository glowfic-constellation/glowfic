class RemoveUniquenessFromCharacterUsernames < ActiveRecord::Migration
  def change
    remove_index :characters, :screenname
  end
end
