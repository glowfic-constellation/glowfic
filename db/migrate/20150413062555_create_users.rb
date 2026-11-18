class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :crypted, null: false
      t.integer :avatar_id
      t.integer :active_character_id
      t.integer :per_page, default: 25
      t.timestamps null: true
    end
    add_index :users, :username, unique: true
  end
end
