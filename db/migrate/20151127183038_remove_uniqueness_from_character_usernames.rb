class RemoveUniquenessFromCharacterUsernames < ActiveRecord::Migration[4.2]
  def change
    remove_index :characters, :screenname
  end
end
