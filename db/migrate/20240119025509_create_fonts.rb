class CreateFonts < ActiveRecord::Migration[7.1]
  def change
    create_table :fonts do |t|
      t.string :name, :null => false
      t.string :css
      t.timestamps
    end

    create_table :post_fonts do |t|
      t.belongs_to :post
      t.belongs_to :font
      t.timestamps
    end
  end
end
