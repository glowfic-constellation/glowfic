class AddDescriptionToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :description, :string
  end
end
