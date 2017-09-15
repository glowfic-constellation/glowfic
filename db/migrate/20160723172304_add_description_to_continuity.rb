class AddDescriptionToContinuity < ActiveRecord::Migration[4.2]
  def change
    add_column :boards, :description, :text
  end
end
