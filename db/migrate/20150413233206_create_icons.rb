class CreateIcons < ActiveRecord::Migration
  def up
    create_table :icons do |t|
      t.integer :user_id, :null => false
      t.string :url, :null => false
      t.timestamps
    end
  end

  def down
    drop_table :icons
  end
end
