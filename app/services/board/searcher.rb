class Board::Searcher < Object
  def initialize
    @search_results = Board.unscoped
  end

  def search(params, page:)
    search_authors(params[:author_id]) if params[:author_id].present?
    @search_results = @search_results.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    @search_results.ordered.paginate(per_page: 25, page: page)
  end

  def search_authors(author_ids)
    author_boards = author_ids.map { |author_id| BoardAuthor.where(user_id: author_id).pluck(:board_id) }.reduce(:&).uniq
    @search_results = @search_results.where(id: author_boards)
  end
end
