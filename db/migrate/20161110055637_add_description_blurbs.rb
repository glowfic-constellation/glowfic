class AddDescriptionBlurbs < ActiveRecord::Migration
  def change
    add_column :characters, :description, :text
    add_column :templates, :description, :text
  end
end
