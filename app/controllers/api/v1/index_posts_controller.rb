class Api::V1::IndexPostsController < Api::ApiController
  before_action :login_required
  resource_description do
    name 'Index Posts'
    description 'Viewing and editing index posts'
  end

  api :POST, '/index_posts/reorder', 'Update the order of posts. This is an unstable feature, and may be moved or renamed; it should not be trusted.'
  error 401, "You must be logged in"
  error 403, "Index is not editable by the user"
  error 404, "Post IDs could not be found"
  error 422, "Invalid parameters provided"
  param :ordered_post_ids, Array, allow_blank: false
  param :section_id, :number, required: false
  def reorder
    list = super(params[:ordered_post_ids], model_klass: IndexPost, model_name: 'post', parent_klass: Index,
      section_klass: IndexSection, section_id: params[:section_id])
    return if performed?
    render json: {post_ids: list}
  end
end
