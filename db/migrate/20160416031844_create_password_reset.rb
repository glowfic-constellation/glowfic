class CreatePasswordReset < ActiveRecord::Migration
  def change
    create_table :password_resets do |t|
      t.integer :user_id, null: false
      t.string :auth_token, null: false
      t.boolean :used, default: false
      t.timestamps null: true
    end
    add_index :password_resets, :auth_token, unique: true
    add_index :password_resets, [:user_id, :created_at]
  end
end
