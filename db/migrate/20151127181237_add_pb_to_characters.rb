class AddPbToCharacters < ActiveRecord::Migration
  def change
    add_column :characters, :pb, :string
  end
end
