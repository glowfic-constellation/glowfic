class AddRetiredToCharacters < ActiveRecord::Migration
  def change
    add_column :characters, :retired, :boolean, default: false
  end
end
