class Api::V1::BoardsController < Api::ApiController
  def show
    unless board = Board.find_by_id(params[:id])
      error = {message: "Continuity could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    render json: {data: board}
  end
end
