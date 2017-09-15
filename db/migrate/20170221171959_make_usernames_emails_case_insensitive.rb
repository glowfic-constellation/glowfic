class MakeUsernamesEmailsCaseInsensitive < ActiveRecord::Migration[4.2]
  def up
    change_column :users, :username, :citext
    change_column :users, :email, :citext
  end

  def down
    change_column :users, :username, :string
    change_column :users, :email, :string
  end
end
