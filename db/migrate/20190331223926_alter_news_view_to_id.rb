class AlterNewsViewToId < ActiveRecord::Migration[5.2]
  def change
    remove_column :news_views, :read_at
    add_column :news_views, :news_id, :integer
  end
end
