class CreateUserTags < ActiveRecord::Migration[5.2]
  def change
    create_table :user_tags do |t|
      t.integer :user_id, null: false, index: true
      t.integer :tag_id, null: false, index: true

      t.timestamps
    end
  end
end
