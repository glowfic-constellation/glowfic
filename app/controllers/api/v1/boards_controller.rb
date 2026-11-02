# frozen_string_literal: true
class Api::V1::BoardsController < Api::ApiController
  resource_description do
    name 'Continuities'
    description 'Viewing, searching, and editing continuities'
  end

  api :GET, '/boards', 'Load all the continuities that match the given query, results ordered by name'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 422, "Invalid parameters provided"
  def index
    queryset = Board.where("name ILIKE ?", params[:q].to_s + '%').ordered
    boards = paginate queryset, per_page: 25
    render json: { results: boards }
  end

  api :GET, '/boards/:id', 'Load a single continuity as a JSON resource, with its sections in section order.'
  param :id, :number, required: true, desc: 'Continuity ID'
  description <<~DESC
    The response includes `authors_locked` and `ordered`. `ordered` is true when the continuity's authors are
    locked or it has sections. The HTML continuity page lists the posts of an ordered continuity in section
    order, and the posts of other continuities newest first. Use `order=board` on `/boards/:id/posts` to get
    the posts in the same order.
  DESC
  error 404, "Continuity not found"
  def show
    unless (board = Board.find_by(id: params[:id]))
      error = { message: "Continuity could not be found." }
      render json: { errors: [error] }, status: :not_found and return
    end

    render json: board.as_json(include: [:board_sections, :ordered])
  end

  api :GET, '/boards/:id/posts', 'Load all posts in the specified continuity'
  param :id, :number, required: true, desc: "Continuity ID"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :order, ['id', 'board', 'tagged_at'], required: false, desc: <<~DESC.squish
    Result ordering: 'id' (default, oldest post first), 'board' (the order of the HTML continuity page) or
    'tagged_at' (most recently updated first). For an ordered continuity, 'board' gives the posts of each
    section in section order, then the posts in no section. For other continuities, 'board' is the same as
    'tagged_at'.
  DESC
  error 404, "Continuity not found"
  error 422, "Invalid parameters provided"
  def posts
    unless (board = Board.find_by(id: params[:id]))
      error = { message: "Continuity could not be found." }
      render json: { errors: [error] }, status: :not_found and return
    end

    # the same filters as the HTML continuity page: visibility, and posts hidden by the user's blocks
    queryset = board.posts.visible_to(current_user)
    queryset = queryset.where.not(id: current_user.hidden_posts) if logged_in?
    queryset = order_board_posts(queryset, board)
      .with_reply_count
      .select('posts.*')
      .preload(:board, :joined_authors, :section)
    posts = paginate(queryset, per_page: 25)
    render json: { results: posts }
  end

  private

  def order_board_posts(queryset, board)
    case params[:order]
      when 'tagged_at'
        queryset.ordered
      when 'board'
        return queryset.ordered unless board.ordered?
        # the HTML page shows the sections in section order, each with its posts in section order,
        # then the posts in no section (NULL section orders sort last in ascending order);
        # the ids are tiebreakers to keep pages stable
        queryset
          .left_joins(:section)
          .merge(BoardSection.ordered)
          .order(BoardSection.arel_table[:id].asc.nulls_last)
          .ordered_in_section
          .ordered_by_id
      else
        queryset.ordered_by_id
    end
  end
end
