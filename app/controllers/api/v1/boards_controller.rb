class Api::V1::BoardsController < Api::ApiController
  resource_description do
    name 'Continuities'
    description 'Viewing and editing continuities'
  end

  api! 'Load a single continuity as a JSON resource.'
  param :id, :number, required: true, desc: 'Continuity ID'
  error 404, "Continuity not found"
  example "'errors': [{'message': 'Continuity could not be found.'}]"
  example "{
  'id': 1,
  'name': 'Continuity',
  'board_sections': [{
      'id': 2,
      'name': 'Subcontinuity',
      'order': 0
    }, {
      'id': 3,
      'name': 'Subcontinuity 2',
      'order': 1
  }]
}"
  def show
    unless board = Board.find_by_id(params[:id])
      error = {message: "Continuity could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    render json: board.as_json(include: [:board_sections])
  end
end
