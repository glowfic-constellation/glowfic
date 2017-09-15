class AddReportIndexesToDateFields < ActiveRecord::Migration[4.2]
  def change
    add_index :replies, :created_at
    add_index :posts, :tagged_at
    add_index :posts, :created_at
  end
end
