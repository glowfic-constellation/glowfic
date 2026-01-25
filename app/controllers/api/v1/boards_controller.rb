# frozen_string_literal: true
class Api::V1::BoardsController < Api::ApiController
  resource_description do
    name 'Continuities'
    description 'Viewing, searching, and editing continuities'
  end

  api :GET, '/boards', 'Load all the continuities that match the given query, results ordered by name'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :user_id, :number, required: false, desc: 'ID of the continuity creator (optional)'
  error 422, "Invalid parameters provided"
  def index
    queryset = Board.all
    queryset = queryset.where("name ILIKE ?", params[:q].to_s + '%').ordered if params[:q].present?

    if params[:user_id].present?
      return unless find_object(User, param: :user_id, status: :unprocessable_entity)
      queryset = queryset.where(creator_id: params[:user_id])
    end

    boards = paginate queryset, per_page: 25
    render json: { results: boards }
  end

  api :GET, '/boards/:id', 'Load a single continuity as a JSON resource.'
  param :id, :number, required: true, desc: 'Continuity ID'
  error 404, "Continuity not found"
  def show
    unless (board = Board.find_by(id: params[:id]))
      error = { message: "Continuity could not be found." }
      render json: { errors: [error] }, status: :not_found and return
    end

    render json: board.as_json(include: [:board_sections])
  end

  api :GET, '/boards/:id/posts', 'Load all posts in the specified continuity'
  param :id, :number, required: true, desc: "Continuity ID"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 404, "Continuity not found"
  def posts
    unless (board = Board.find_by(id: params[:id]))
      error = { message: "Continuity could not be found." }
      render json: { errors: [error] }, status: :not_found and return
    end

    queryset = board.posts
      .visible_to(current_user)
      .ordered_by_id
      .with_reply_count
      .select('posts.*')
      .includes(:board, :joined_authors, :section)
    posts = paginate(queryset, per_page: 25)
    render json: { results: posts }
  end
end
