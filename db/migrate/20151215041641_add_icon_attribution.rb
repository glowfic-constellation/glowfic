class AddIconAttribution < ActiveRecord::Migration
  def change
    add_column :icons, :credit, :string
  end
end
