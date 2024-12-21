# frozen_string_literal: true
class Api::V1::BookmarksController < Api::ApiController
  before_action :login_required
  before_action :find_bookmark

  resource_description do
    description 'Updating a bookmark'
  end

  api :PATCH, '/bookmarks/:id', 'Update a single bookmark. Currently only supports renaming.'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :id, :number, required: true, desc: "Bookmark ID"
  param :name, String, required: true, allow_blank: true, desc: "Bookmark's new name"
  error 403, "Bookmark is not visible to the user"
  error 404, "Bookmark not found"
  error 422, "Invalid parameters provided"
  def update
    if @bookmark.user.id != current_user.try(:id)
      access_denied
      return
    end

    unless @bookmark.update(name: params[:name])
      error = { message: 'Bookmark could not be updated.' }
      render json: { errors: [error] }, status: :unprocessable_entity
      return
    end

    render json: { name: @bookmark.name }
  end

  private

  def find_bookmark
    return unless (@bookmark = find_object(Bookmark))
    access_denied unless @bookmark.visible_to?(current_user)
  end
end
