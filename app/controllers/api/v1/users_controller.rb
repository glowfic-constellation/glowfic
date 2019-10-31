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
    users = paginate queryset.active, per_page: 25
    render json: {results: users}
  end

  api :GET, '/users/:id/posts', 'Load all posts where the specified user is an author'
  param :authorship, :number, required: false, desc: 'Level of involvement in a post. TODO define'
  error 404, "User not found"
  def posts
    return unless (user = find_object(User))
    
    posts = Post.where(privacy: Concealable::PUBLIC) # TODO expand when OAuth exists
    case params[:authorship] # TODO does not include first-poster-or-cameo-not-different-primary-author, seems too edge case
    when 1 # only posts you were the first post
      posts = posts.where(user: user)
    when 2 # only posts you are any of the primary authors # TODO wait for creators to have PostAuthors
      posts = posts.where(id: PostAuthor.where(user: user).select(:post_id))
    when 3 # only posts where you are a cameo author
    when 4 # only posts where you are a primary author, not first poster or cameo
    when 5 # only posts where you are not the starter
      posts = posts.where(id: PostAuthor.where(user: user).select(:post_id)).where.not(user: user)
    else # default to all posts they have joined as any of first poster, primary author or cameo author
    end
  end
end
