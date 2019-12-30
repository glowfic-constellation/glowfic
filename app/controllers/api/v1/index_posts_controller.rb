class Api::V1::IndexPostsController < Api::ApiController
  before_action :login_required
  resource_description do
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
    reorderer = Reorderer.new(IndexPost, Index, current_user)
    reorderer.section_id = params[:section_id]
    reorderer.new_ordering_ids = params[:ordered_post_ids]
    ordered_ids = reorderer.reorder

    if reorderer.succeeded?
      render json: {post_ids: ordered_ids}
    else
      error = reorderer.error
      render json: {errors: [{message: error[:message]}]}, status: error[:status]
    end
  end
end
