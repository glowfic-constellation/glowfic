class Api::V1::BoardSectionsController < Api::ApiController
  before_action :login_required

  resource_description do
    name 'Subcontinuities'
    description 'Viewing and editing subcontinuities'
  end

  api :POST, '/board_sections/reorder', 'Update the order of subcontinuities. This is an unstable feature, and may be moved or renamed; it should not be trusted.'
  error 401, "You must be logged in"
  error 403, "Board is not editable by the user"
  error 404, "Section IDs could not be found"
  error 422, "Invalid parameters provided"
  param :ordered_section_ids, Array, allow_blank: false
  def reorder
    list = super(params[:ordered_section_ids], model_klass: BoardSection, model_name: 'section', parent_klass: Board)
    return if performed?
    render json: {section_ids: list}
  end
end
