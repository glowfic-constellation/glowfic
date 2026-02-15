class CreateBoards < ActiveRecord::Migration[4.2]
  def change
    create_table :boards do |t|
      t.string :name, :null => false
      t.integer :creator_id, :null => false
      t.integer :coauthor_id
      t.timestamps null: true
    end
  end
end
