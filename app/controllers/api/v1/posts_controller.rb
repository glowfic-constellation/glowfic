class Api::V1::PostsController < Api::ApiController
  before_action :login_required, except: [:index, :show]
  before_action :find_post, only: [:show, :update]

  resource_description do
    description 'Viewing and editing posts'
  end

  api :GET, '/posts', 'Load all posts optionally filtered by subject'
  param :q, String, required: false, desc: 'Subject search term'
  def index
    queryset = Post.order(Arel.sql('LOWER(subject) asc'))
    queryset = queryset.where('LOWER(subject) LIKE ?', "%#{params[:q].downcase}%") if params[:q].present?

    posts = paginate queryset, per_page: 25
    posts = posts.visible_to(current_user)
    render json: {results: posts.as_json(min: true)}
  end

  api :GET, '/posts/:id', 'Load a single post as a JSON resource'
  param :id, :number, required: true, desc: "Post ID"
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  def show
    render json: @post.as_json(include: [:character, :icon, :content])
  end

  api :PATCH, '/posts/:id', 'Update a single post. Currently only supports saving the private note for an author.'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :id, :number, required: true, desc: "Post ID"
  param :private_note, String, required: true, desc: "Author's private notes about this post"
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  error 422, "Invalid parameters provided"
  def update
    author = @post.author_for(current_user)
    unless author.present?
      access_denied
      return
    end

    unless author.update(private_note: params[:private_note])
      error = {message: 'Post could not be updated.'}
      render json: {errors: [error]}, status: :unprocessable_entity
      return
    end

    render json: {private_note: helpers.sanitize_written_content(params[:private_note])}
  end

  api :POST, '/posts/reorder', 'Update the order of posts. This is an unstable feature, and may be moved or renamed; it should not be trusted.'
  error 401, "You must be logged in"
  error 403, "Board is not editable by the user"
  error 404, "Post IDs could not be found"
  error 422, "Invalid parameters provided"
  param :ordered_post_ids, Array, allow_blank: false
  param :section_id, :number, required: false
  def reorder
    reorderer = ApiReorderer.new(model_klass: Post, parent_klass: Board, section_klass: BoardSection,
      section_key: :section_id, section_id: params[:section_id])
    list = reorderer.reorder(params[:ordered_post_ids], user: current_user)
    if reorderer.status.present?
      render json: {errors: reorderer.errors}, status: reorderer.status
    else
      render json: {post_ids: list}
    end
  end

  private

  def find_post
    return unless (@post = find_object(Post))
    access_denied unless @post.visible_to?(current_user)
  end
end
