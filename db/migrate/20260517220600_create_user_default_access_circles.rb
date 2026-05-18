class CreateUserDefaultAccessCircles < ActiveRecord::Migration[7.2]
  def change
    create_table :user_default_access_circles do |t|
      t.integer :user_id, null: false
      t.integer :tag_id, null: false
      t.timestamps null: true
    end
    add_index :user_default_access_circles, :user_id
    add_index :user_default_access_circles, [:user_id, :tag_id], unique: true
  end
end
