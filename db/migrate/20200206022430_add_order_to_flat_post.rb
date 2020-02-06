class AddOrderToFlatPost < ActiveRecord::Migration[5.2]
  def change
    add_column :flat_posts, :order, :integer, default: 0
  end
end
