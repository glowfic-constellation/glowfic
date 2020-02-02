class AddNewOrderToReply < ActiveRecord::Migration[5.2]
  def change
    add_column :replies, :new_order, :integer
  end
end
