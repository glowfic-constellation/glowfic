class AddUser < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :username, :null => false
      t.string :crypted, :null => false
      t.string :avatar
      t.timestamps
    end
    add_index :users, :username, :unique => true
  end

  def down
    drop_table :users
  end
end
