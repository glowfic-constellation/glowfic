class Api::V1::UsersController < Api::ApiController
  resource_description do
    description 'Viewing and searching users'
  end

  api! 'Load all the users that match the given query, results ordered by username'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 422, "Invalid parameters provided"
  def index
    queryset = User.where("username LIKE ?", params[:q].to_s + '%').order('username asc')
    users = paginate queryset, per_page: 25
    render json: {results: users}
  end
end
