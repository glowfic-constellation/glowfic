class Api::V1::TemplatesController < Api::ApiController
  resource_description do
    description 'Viewing and searching templates'
  end

  api :GET, '/templates', 'Load all the templates that match the given query, results ordered by name'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 422, "Invalid parameters provided"
  def index
    queryset = Template.where("name LIKE ?", params[:q].to_s + '%').order('name asc')
    templates = paginate queryset, per_page: 25
    render json: {results: templates}
  end
end
