class Api::V1::UsersController < Api::ApiController
  resource_description do
    description 'Viewing and searching users'
  end

  api :GET, '/users', 'Load all the users that match the given query, results ordered by username'
  param :q, String, required: false, desc: "Query string"
  param :match, String, required: false, desc: "If set to 'exact', requires exact username match on q instead of prefix match"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :hide_unblockable, ['true', 'false'], required: false, desc: "If set to 'true', elimiates users who cannot be blocked from the result"
  error 422, "Invalid parameters provided"
  def index
    queryset = if params[:match] == 'exact'
      User.where(username: params[:q])
    else
      User.where("username LIKE ?", params[:q].to_s + '%').ordered
    end
    if params[:hide_unblockable].present? && params[:hide_unblockable] == 'true' && logged_in?
      blocked_users = Block.where(blocking_user_id: current_user.id).pluck(:blocked_user_id)
      queryset = queryset.where.not(id: blocked_users + [current_user.id])
    end
    users = paginate queryset, per_page: 25
    render json: {results: users}
  end
end
