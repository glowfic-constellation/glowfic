class Api::V1::BoardsController < Api::ApiController
  resource_description do
    name 'Continuities'
    description 'Viewing and editing continuities'
  end

  api! 'Load a single continuity as a JSON resource.'
  param :id, :number, required: true, desc: 'Continuity ID'
  error 404, "Continuity not found"
  def show
    unless board = Board.find_by_id(params[:id])
      error = {message: "Continuity could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    render json: board.as_json(include: [:board_sections])
  end
end
