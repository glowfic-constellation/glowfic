class AddNotesToAuthors < ActiveRecord::Migration[5.2]
  def change
    add_column :post_authors, :private_note, :text
  end
end
