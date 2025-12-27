# frozen_string_literal: true
class Api::V1::GalleriesController < Api::ApiController
  resource_description do
    description 'Viewing and editing galleries'
  end

  api :GET, '/galleries/:id', 'Load a single gallery as a JSON resource'
  param :id, :number, required: true, desc: 'Gallery ID. May pass 0 to represent icons without a gallery.'
  param :user_id, :number, required: false, desc: 'User ID required when accessing galleryless icons while logged out.'
  error 404, "Gallery not found"
  error 422, "User ID required but missing or invalid"
  def show
    show_galleryless and return if params[:id].to_s == '0'

    unless (gallery = Gallery.find_by(id: params[:id]))
      error = { message: "Gallery could not be found." }
      render json: { errors: [error] }, status: :not_found and return
    end
    render json: { name: gallery.name, icons: gallery.icons }
  end

  private

  def show_galleryless
    user = if params[:user_id].present?
      User.active.find_by(id: params[:user_id])
    else
      current_user
    end

    unless user
      error = { message: "Gallery user could not be found." }
      render json: { errors: [error] }, status: :unprocessable_entity and return true
    end
    render json: { name: 'Galleryless', icons: user.galleryless_icons }
  end
end
