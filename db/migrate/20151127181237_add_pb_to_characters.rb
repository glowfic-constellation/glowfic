class AddPbToCharacters < ActiveRecord::Migration[4.2]
  def change
    add_column :characters, :pb, :string
  end
end
