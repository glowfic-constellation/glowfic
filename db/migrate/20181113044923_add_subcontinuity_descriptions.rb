class AddSubcontinuityDescriptions < ActiveRecord::Migration[5.1]
  def change
     add_column :board_sections, :description, :text
  end
end
