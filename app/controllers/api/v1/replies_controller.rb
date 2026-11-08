# frozen_string_literal: true
class Api::V1::RepliesController < Api::ApiController
  # filters that name a record, checked for existence before searching
  SEARCH_FILTERS = {
    author_id: User,
    board_id: Board,
    character_id: Character,
    icon_id: Icon,
    template_id: Template,
  }.freeze
  SEARCH_PARAMS = [:subj_content, :sort, :exclude_board_ids, *SEARCH_FILTERS.keys].freeze

  resource_description do
    description 'Viewing replies'
  end

  api :GET, '/posts/:id/replies', 'Load all the replies for a given post as JSON resources'
  param :post_id, :number, required: true, desc: "Post ID"
  param :page, :number, required: false, desc: 'Page in results'
  param :per_page, :number, required: false, desc: 'Number of replies to load per page. Defaults to 25, accepts values from 1-100 inclusive.'
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  def index
    return unless (post = find_object(Post, param: :post_id))
    access_denied and return unless post.visible_to?(current_user)

    replies = post.replies
      .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username, users.deleted as user_deleted, character_aliases.name as alias')
      .joins(:user)
      .left_outer_joins(:character)
      .left_outer_joins(:icon)
      .left_outer_joins(:character_alias)
      .ordered
    paginate json: replies, per_page: per_page
  end

  api :GET, '/replies', 'Search replies, with the same filters and visibility rules as the reply search page. Returns 25 replies per page.'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]". Optional; without it, only public posts are searched.', required: false
  param :subj_content, String, required: false, desc: 'Full-text search of reply content. Each phrase in double quotes must also appear exactly (case-insensitive).'
  param :author_id, :number, required: false, desc: 'If provided, returns only replies written by the given user'
  param :character_id, :number, required: false, desc: 'If provided, returns only replies written as the given character'
  param :template_id, :number, required: false, desc: 'If provided, returns only replies written as any character in the given template'
  param :icon_id, :number, required: false, desc: 'If provided, returns only replies that use the given icon'
  param :board_id, :number, required: false, desc: 'If provided, returns only replies in posts in the given continuity'
  param :exclude_board_ids, Array, of: :number, required: false, desc: 'If provided, leaves out replies in posts in the given continuities. Ignored when post_id is given.'
  param :post_id, :number, required: false, desc: 'If provided, returns only replies in the given post'
  param :sort, ['rank', 'created_new', 'created_old'], required: false,
    desc: "Result ordering: 'rank' (default; best match first for a content search, else newest first), 'created_new' (newest first) or 'created_old' (oldest first)"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 403, "Post is not visible to the user"
  error 422, "Invalid parameters provided"
  def search
    post = nil
    if params[:post_id].present?
      return unless (post = find_object(Post, param: :post_id, status: :unprocessable_content))
      access_denied and return unless post.visible_to?(current_user)
    end

    # find_object renders the 422, so stop at the first missing record
    missing = SEARCH_FILTERS.any? do |key, klass|
      params[key].present? && !find_object(klass, param: key, status: :unprocessable_content)
    end
    return if missing

    # the same search, visibility and block rules as RepliesController#search;
    # condensed and show_blocked are page display options and are not passed through
    search_params = params.slice(*SEARCH_PARAMS)
    searcher = Reply::Searcher.new(current_user: current_user, post: post)
    searcher.setup(search_params)
    replies = searcher.search(search_params)
      .select('character_aliases.name as alias')
      .left_outer_joins(:character_alias)

    includes = [:post]
    includes << :highlight if params[:subj_content].present?
    replies = paginate replies, per_page: 25
    render json: { results: replies.as_json(include: includes) }
  end

  api :GET, '/replies/:id/bookmark', "Load a user's bookmark attached to a reply if it exists and is visible"
  param :id, :number, required: true, desc: "Reply ID"
  param :user_id, :number, required: true, desc: "User ID"
  error 403, "Reply's post is not visible to the user"
  error 404, "Reply or user not found"
  error 422, "Invalid parameters provided"
  def bookmark
    return unless (reply = find_object(Reply))
    return unless (user = find_object(User, param: :user_id))
    access_denied and return unless reply.post.visible_to?(current_user)

    bookmark = reply.bookmarks.find_by(user_id: user.id, type: "reply_bookmark")
    bookmark_not_found and return unless bookmark&.visible_to?(current_user)

    render json: bookmark.as_json
  end

  private

  def bookmark_not_found
    error = { message: "Bookmark could not be found." }
    render json: { errors: [error] }, status: :not_found
  end
end
