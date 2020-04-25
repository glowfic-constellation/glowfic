class AddClusterToCharacter < ActiveRecord::Migration[5.2]
  def change
    add_column :characters, :cluster, :string
  end
end
