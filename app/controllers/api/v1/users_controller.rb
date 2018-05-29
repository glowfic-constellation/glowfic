class Api::V1::UsersController < Api::ApiController
  resource_description do
    description 'Viewing and searching users'
  end

  api! 'Load all the users that match the given query, results ordered by username'
  param :q, String, required: false, desc: "Query string"
  param :match, String, required: false, desc: "If set to 'exact', requires exact username match on q instead of prefix match"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 422, "Invalid parameters provided"
  def index
    queryset = if params[:match] == 'exact'
      User.where(username: params[:q])
    else
      User.where("username LIKE ?", params[:q].to_s + '%').ordered
    end
    users = paginate queryset, per_page: 25
    render json: {results: users}
  end
end
