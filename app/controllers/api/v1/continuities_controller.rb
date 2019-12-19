class Api::V1::ContinuitiesController < Api::ApiController
  before_action :find_continuity, except: :index

  resource_description do
    name 'Continuities'
    description 'Viewing, searching, and editing continuities'
  end

  api :GET, '/continuities', 'Load all the continuities that match the given query, results ordered by name'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 422, "Invalid parameters provided"
  def index
    queryset = Continuity.where("name LIKE ?", params[:q].to_s + '%').ordered
    continuities = paginate queryset, per_page: 25
    render json: {results: continuities}
  end

  api :GET, '/continuities/:id', 'Load a single continuity as a JSON resource.'
  param :id, :number, required: true, desc: 'Continuity ID'
  error 404, "Continuity not found"
  def show
    render json: @continuity.as_json(include: [:subcontinuities])
  end

  api :GET, '/continuities/:id/posts', 'Load all posts in the specified continuity'
  param :id, :number, required: true, desc: "Continuity ID"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 404, "Continuity not found"
  def posts
    queryset = Post.where(privacy: Concealable::PUBLIC, continuity_id: @continuity.id).with_reply_count.select('posts.*')
    posts = paginate queryset.includes(:continuity, :joined_authors, :section), per_page: 25
    render json: {results: posts}
  end

  private

  def find_continuity
    @continuity = find_object(Continuity)
  end
end
