class CreateTemplates < ActiveRecord::Migration
  def change
    create_table :templates do |t|
      t.integer :user_id, :null => false
      t.string :name
      t.timestamps
    end
  end
end
