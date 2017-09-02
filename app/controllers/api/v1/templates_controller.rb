class Api::V1::TemplatesController < Api::ApiController
  resource_description do
    description 'Viewing and searching templates'
  end

  api :GET, '/templates', 'Load all the templates that match the given query, results ordered by name'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :user_id, :number, required: false, desc: 'ID of the template user (optional)'
  error 422, "Invalid parameters provided"
  def index
    queryset = Template.where("name LIKE ?", params[:q].to_s + '%').order('name asc')

    if params[:user_id].present?
      unless User.find_by_id(params[:user_id])
        error = {message: "User could not be found."}
        render json: {errors: [error]}, status: :unprocessable_entity and return
      end
      queryset = queryset.where(user_id: params[:user_id])
    end

    templates = paginate queryset, per_page: 25
    render json: {results: templates}
  end
end
