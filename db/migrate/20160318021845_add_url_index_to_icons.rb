class AddUrlIndexToIcons < ActiveRecord::Migration[4.2]
  def change
    add_index :icons, :url
  end
end
