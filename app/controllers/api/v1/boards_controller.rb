class Api::V1::BoardsController < Api::ApiController
  resource_description do
    name 'Continuities'
    description 'Viewing, searching, and editing continuities'
  end

  api :GET, '/boards', 'Load all the continuities that match the given query, results ordered by name'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 422, "Invalid parameters provided"
  def index
    queryset = Board.where("name LIKE ?", params[:q].to_s + '%').order('pinned DESC, LOWER(name)')
    boards = paginate queryset, per_page: 25
    render json: {results: boards}
  end

  api! 'Load a single continuity as a JSON resource.'
  param :id, :number, required: true, desc: 'Continuity ID'
  error 404, "Continuity not found"
  def show
    unless (board = Board.find_by_id(params[:id]))
      error = {message: "Continuity could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    render json: board.as_json(include: [:board_sections])
  end
end
