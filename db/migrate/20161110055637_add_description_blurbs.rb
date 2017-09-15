class AddDescriptionBlurbs < ActiveRecord::Migration[4.2]
  def change
    add_column :characters, :description, :text
    add_column :templates, :description, :text
  end
end
