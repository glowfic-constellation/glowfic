class AddRetiredToCharacters < ActiveRecord::Migration[5.2]
  def change
    add_column :characters, :retired, :boolean, default: false
  end
end
