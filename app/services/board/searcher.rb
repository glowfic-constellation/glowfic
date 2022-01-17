class Board::Searcher < Object
  def initialize
    @search_results = Board.unscoped
  end

  def search(params)
    search_authors(params[:author_id]) if params[:author_id].present?
    @search_results = @search_results.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    @search_results
  end

  def search_authors(author_ids)
    # get author matches for boards that have at least one
    author_boards = BoardAuthor.where(user_id: author_ids).group(:board_id)
    # select boards that have all of them
    author_boards = author_boards.having('COUNT(board_authors.user_id) = ?', author_ids.length).pluck(:board_id)
    @search_results = @search_results.where(id: author_boards)
  end
end
