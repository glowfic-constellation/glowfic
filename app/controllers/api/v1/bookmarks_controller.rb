# frozen_string_literal: true
class Api::V1::BookmarksController < Api::ApiController
  before_action :login_required
  before_action :find_bookmark, except: :create

  resource_description do
    description 'Viewing and modifying bookmarks'
  end

  api :POST, '/bookmarks', 'Create a bookmark for the current user at a reply. If one already exists, update it.'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :reply_id, :number, required: true, desc: "Reply ID"
  param :name, String, required: false, allow_blank: true, desc: "New bookmark's name"
  param :public, :boolean, required: false, allow_blank: true, desc: "New bookmark's public status"
  error 403, "Reply is not visible to the user"
  error 404, "Reply not found"
  error 422, "Invalid parameters provided"
  def create
    return unless (reply = find_object(Reply, param: :reply_id))
    unless reply.post.visible_to?(current_user)
      access_denied
      return
    end

    bookmark = Bookmark.where(user: current_user, reply: reply, type: "reply_bookmark").first_or_initialize
    params[:post_id] = reply.post_id
    unless bookmark.update(params.permit(:name, :public, :post_id))
      error = { message: 'Bookmark could not be created.' }
      render json: { errors: [error] }, status: :unprocessable_entity
      return
    end

    render json: bookmark.as_json
  end

  api :PATCH, '/bookmarks/:id', 'Update a single bookmark.'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :id, :number, required: true, desc: "Bookmark ID"
  param :name, String, required: false, allow_blank: true, desc: "Bookmark's new name"
  param :public, :boolean, required: false, allow_blank: true, desc: "Bookmark's new public status"
  error 403, "Bookmark is not visible to the user"
  error 404, "Bookmark not found"
  error 422, "Invalid parameters provided"
  def update
    if @bookmark.user.id != current_user.try(:id)
      access_denied
      return
    end

    unless @bookmark.update(params.permit(:name, :public))
      error = { message: 'Bookmark could not be updated.' }
      render json: { errors: [error] }, status: :unprocessable_entity
      return
    end

    render json: @bookmark.as_json
  end

  api :DELETE, '/bookmarks/:id', 'Removes a bookmark'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :id, :number, required: true, desc: "Bookmark ID"
  error 403, "Bookmark is not visible to the user"
  error 404, "Bookmark not found"
  error 422, "Invalid parameters provided"
  def destroy
    if @bookmark.user.id != current_user.try(:id)
      access_denied
      return
    end

    unless @bookmark.destroy
      error = { message: 'Bookmark could not be removed.' }
      render json: { errors: [error] }, status: :unprocessable_entity
      return
    end

    head :no_content
  end

  private

  def find_bookmark
    return unless (@bookmark = find_object(Bookmark))
    access_denied unless @bookmark.visible_to?(current_user)
  end
end
