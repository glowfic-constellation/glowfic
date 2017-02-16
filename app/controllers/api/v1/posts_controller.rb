class Api::V1::PostsController < Api::ApiController
  resource_description do
    description 'Viewing and editing posts'
  end

  api! 'Load a single post as a JSON resource'
  param :id, :number, required: true, desc: "Post ID"
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  def show
    unless post = Post.find_by_id(params[:id])
      error = {message: "Post could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    access_denied and return unless post.visible_to?(current_user)
    render json: post
  end
end
