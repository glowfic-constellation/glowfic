# frozen_string_literal: true
class Api::V1::UsersController < Api::ApiController
  before_action :find_user, except: :index

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
      User.where("username ILIKE ?", params[:q].to_s + '%').ordered
    end
    if params[:hide_unblockable].present? && params[:hide_unblockable] == 'true' && logged_in?
      blocked_users = Block.where(blocking_user_id: current_user.id).pluck(:blocked_user_id)
      queryset = queryset.where.not(id: blocked_users + [current_user.id])
    end
    users = paginate queryset.active, per_page: 25
    render json: { results: users.as_json(detailed: true) }
  end

  api :GET, '/users/:id/posts', 'Load all posts where the specified user is an author'
  param :id, :number, required: true, desc: "User ID"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 404, "User not found"
  def posts
    post_ids = Post::Author.where(user: @user).pluck(:post_id)
    queryset = Post.privacy_public.where(id: post_ids).with_reply_count.select('posts.*')
    posts = paginate queryset.includes(:board, :joined_authors, :section), per_page: 25
    render json: { results: posts }
  end

  api :GET, '/users/:id/bookmarks', "Load all of a user's bookmarks, optionally limited to a single post"
  param :id, :number, required: true, desc: "User ID"
  param :post_id, :number, required: false, desc: "Post ID"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 403, "Bookmarks are not visible to the user"
  error 404, "User not found"
  error 422, "Invalid parameters provided"
  def bookmarks
    render json: { bookmarks: [] } and return unless @user.public_bookmarks || @user.id == current_user.try(:id)

    bookmarks = @user.bookmarks.visible_to(current_user)
    bookmarks = bookmarks.where(post_id: params[:post_id]) if params[:post_id].present?

    bookmarks = paginate bookmarks.order(:id), per_page: 25
    render json: { bookmarks: bookmarks }
  end

  private

  def find_user
    @user = find_object(User)
  end
end
