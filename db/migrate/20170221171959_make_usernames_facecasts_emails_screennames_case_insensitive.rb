class MakeUsernamesFacecastsEmailsScreennamesCaseInsensitive < ActiveRecord::Migration
  def up
    change_column :users, :username, :citext
    change_column :users, :email, :citext
    change_column :characters, :pb, :citext
    change_column :characters, :screenname, :citext
  end

  def down
    change_column :users, :username, :string
    change_column :users, :email, :string
    change_column :characters, :pb, :string
    change_column :characters, :screenname, :string
  end
end
