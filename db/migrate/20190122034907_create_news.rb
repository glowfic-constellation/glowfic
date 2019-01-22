class CreateNews < ActiveRecord::Migration[5.2]
  def change
    create_table :news do |t|
      t.integer :user_id, null: false
      t.text :content
      t.timestamps
    end

    create_table :news_views do |t|
      t.integer :user_id, null: false
      t.datetime :read_at
      t.timestamps
    end
    add_index :news_views, :user_id
  end
end
