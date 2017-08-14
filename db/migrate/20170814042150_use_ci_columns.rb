class UseCiColumns < ActiveRecord::Migration
  def up
    change_column :boards, :name, :citext
    change_column :characters, :name, :citext
    change_column :templates, :name, :citext
  end

  def down
    change_column :boards, :name, :string
    change_column :characters, :name, :string
    change_column :templates, :name, :string
  end
end
