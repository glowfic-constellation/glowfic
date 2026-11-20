# frozen_string_literal: true
class Api::V1::UsersController < Api::ApiController
  before_action :find_user, except: [:index, :galleries]
  before_action :find_gallery_user, only: :galleries

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
  error 404, "User not found"
  error 422, "Invalid parameters provided"
  def bookmarks
    bookmarks = @user.bookmarks.visible_to(current_user)
    bookmarks = bookmarks.where(post_id: params[:post_id]) if params[:post_id].present?

    bookmarks = paginate bookmarks.order(:id), per_page: 25
    render json: { bookmarks: bookmarks }
  end

  api :GET, '/users/:id/galleries', "Load a user's galleries, ordered by name, as on the user's galleries page"
  param :id, :number, required: true, desc: "User ID"
  param :includes, Array, in: ["icons"], of: String, required: false, desc: "Specify additional fields to return in JSON"
  param :page, :number, required: false, desc: 'Page in results'
  param :per_page, :number, required: false, desc: 'Number of galleries to load per page. Defaults to 25, accepts values from 1-100 inclusive.'
  error 404, "User not found"
  error 422, "Invalid parameters provided"
  def galleries
    include_icons = (params[:includes] || []).include?('icons')

    galleries = paginate @user.galleries.ordered_by_name, per_page: per_page
    galleries = galleries.with_icon_count.with_gallery_groups
    galleries = galleries.preload(:icons) if include_icons

    galleryless = { id: 0, name: 'Galleryless', icon_count: @user.galleryless_icons.count, gallery_groups: [] }
    galleryless[:icons] = @user.galleryless_icons if include_icons

    results = galleries.map do |gallery|
      gallery_json = {
        id: gallery.id,
        name: gallery.name,
        icon_count: gallery.icon_count,
        gallery_groups: gallery.gallery_groups_data.map { |group| { id: group.id, text: group.name } },
      }
      gallery_json[:icons] = gallery.icons if include_icons
      gallery_json
    end

    render json: { galleryless: galleryless, results: results }
  end

  private

  def find_user
    @user = find_object(User)
  end

  # matches GalleriesController#find_user: deleted and read-only users have no galleries page
  def find_gallery_user
    return if (@user = User.active.full.find_by(id: params[:id]))
    error = { message: "User could not be found." }
    render json: { errors: [error] }, status: :not_found
  end
end
