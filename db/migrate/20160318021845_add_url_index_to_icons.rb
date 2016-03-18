class AddUrlIndexToIcons < ActiveRecord::Migration
  def change
    add_index :icons, :url
  end
end
