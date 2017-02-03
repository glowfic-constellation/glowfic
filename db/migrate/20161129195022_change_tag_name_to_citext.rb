class ChangeTagNameToCitext < ActiveRecord::Migration
  def up
    execute "CREATE EXTENSION IF NOT EXISTS citext;"
    change_column :tags, :name, :citext
  end

  def down
    change_column :tags, :name, :string
  end
end
