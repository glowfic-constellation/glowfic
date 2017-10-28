class CreateIndexes < ActiveRecord::Migration[5.0]
  def change
    create_table :indexes do |t|
      t.integer :user_id, null: false
      t.citext :name, null: false
      t.text :description
      t.integer :privacy, null: false, default: 0
      t.boolean :open_to_anyone, null: false, default: false
      t.timestamps null: false
    end
    add_index :indexes, :user_id

    create_table :index_sections do |t|
    	t.integer :index_id, null: false
    	t.citext :name, null: false
    	t.text :description
    	t.integer :section_order
    	t.timestamps null: false
    end
    add_index :index_sections, :index_id

    create_table :index_posts do |t|
    	t.integer :post_id, null: false
    	t.integer :index_id, null: false
      t.integer :index_section_id
      t.text :description
    	t.integer :section_order
    	t.timestamps null: false
    end
    add_index :index_posts, :index_id
    add_index :index_posts, :post_id
  end
end
