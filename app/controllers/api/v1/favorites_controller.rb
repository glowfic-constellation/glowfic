# frozen_string_literal: true
class Api::V1::FavoritesController < Api::ApiController
  before_action :login_required

  resource_description do
    description "Viewing the current user's favorites"
  end

  api :GET, '/favorites', "Load the current user's favorites (users, continuities and posts), as on the grouped view of the Favorites page. " \
                          "Results are ordered by favorite type, then by the order the favorites were made. " \
                          "Favorited posts the current user cannot view are left out. " \
                          "To load the posts that result from these favorites, use GET /posts with favorites=true."
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 401, "You must be logged in"
  error 422, "Invalid parameters provided"
  def index
    favorites = current_user.favorites
    visible_post_ids = Post.visible_to(current_user).select(:id)
    favorites = favorites.where.not(favorite_type: Post.to_s).or(favorites.where(favorite_type: Post.to_s, favorite_id: visible_post_ids))

    favorites = paginate favorites.includes(:favorite).order(:favorite_type, :id), per_page: 25
    render json: { favorites: favorites.map { |favorite| favorite_json(favorite) } }
  end

  private

  def favorite_json(favorite)
    {
      id: favorite.id,
      favorite_type: favorite.favorite_type,
      favorite_id: favorite.favorite_id,
      favorite: favorite.favorite.as_json(min: true),
    }
  end
end
