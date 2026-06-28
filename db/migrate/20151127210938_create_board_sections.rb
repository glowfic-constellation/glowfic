class CreateBoardSections < ActiveRecord::Migration[4.2]
  def change
    create_table :board_sections do |t|
      t.integer :board_id, null: false
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.integer :section_order, null: false
      t.timestamps null: true
    end
    add_column :posts, :section_id, :integer
    add_column :posts, :section_order, :integer
    add_column :icons, :attribution, :string
  end
end
