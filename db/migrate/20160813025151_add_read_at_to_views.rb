class AddReadAtToViews < ActiveRecord::Migration[4.2]
  def change
    add_column :post_views, :read_at, :datetime
    add_column :board_views, :read_at, :datetime
    add_column :post_views, :warnings_hidden, :boolean, default: false
    Post::View.all.each do |view|
      view.read_at = view.updated_at
      view.save
    end
    BoardView.all.each do |view|
      view.read_at = view.updated_at
      view.save
    end
  end
end
