class AddOrderToSectionlessPosts < ActiveRecord::Migration
  def up
    Board.all.each do |board|
      posts = board.posts.where(section_id: nil).order('created_at asc')
      next unless posts.present?

      start_order = board.board_sections.count
      posts.each_with_index do |post, index|
        post.section_order = start_order + index
        post.skip_edited = true
        post.save
      end
    end
  end

  def down
    Post.where(section_id: nil).each do |post|
      post.section_order = nil
      post.skip_edited = true
      post.save
    end
  end
end
