class Api::V1::PostsController < Api::ApiController
  before_filter :find_post
  before_filter :login_required, only: :characters_for_tag

  resource_description do
    description 'Viewing and editing posts'
  end

  api! 'Load a single post as a JSON resource'
  param :id, :number, required: true, desc: "Post ID"
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  def show
    render json: @post
  end

  api :GET, '/characters_for_tag', 'Load all the characters a given user can post with, formatted for Select2'
  param :id, :number, required: true, desc: "Post ID"
  error 401, "You must be logged in"
  error 403, "Post is not visible to the user"
  error 422, "Invalid parameters provided"
  def characters_for_tag
    formatted_json = current_user.templates.order('lower(name)').map do |template|
      { text: template.name,
        children: template.characters.order('lower(name)').map { |c| {text: c.selector_name, id: c.id} }
      }
    end

    templateless_chars =  current_user.characters.where(template_id: nil).order('lower(name)')
    if templateless_chars.exist?
      formatted_json << {
        text: 'Templateless',
        children: templateless_chars.map { |c| {text: c.selector_name, id: c.id} }
      }
    end
  end

  private

  def find_post
    unless @post = Post.find_by_id(params[:id])
      error = {message: "Post could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    access_denied and return unless @post.visible_to?(current_user)
  end
end
