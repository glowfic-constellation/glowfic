class Api::V1::IndexSectionsController < Api::ApiController
  before_action :login_required

  resource_description do
    name 'Index Sections'
    description 'Viewing and editing index sections'
  end

  api :POST, '/index_sections/reorder', 'Update the order of index sections. This is an unstable feature, and may be moved or renamed; it should not be trusted.'
  error 401, "You must be logged in"
  error 403, "Index is not editable by the user"
  error 404, "Section IDs could not be found"
  error 422, "Invalid parameters provided"
  param :ordered_section_ids, Array, allow_blank: false
  def reorder
    list = super(params[:ordered_section_ids], model_klass: IndexSection, model_name: 'section', parent_klass: Index)
    return if performed?
    render json: {section_ids: list}
  end
end
