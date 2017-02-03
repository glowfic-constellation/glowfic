class Api::V1::CharactersController < Api::ApiController
  before_filter :login_required, only: :update
  before_filter :find_character
  before_filter :require_permission, only: :update

  def show
    render json: {data: @character}
  end

  def update
    render json: {data: @character} and return unless params[:character]

    errors = []
    if params[:character][:default_icon_id].present?
      errors << {message: "Default icon could not be found"} unless Icon.find_by_id(params[:character][:default_icon_id])
    end

    @character.assign_attributes(params[:character])
    errors += @character.errors.full_messages.map { |msg| {message: msg} } unless @character.valid?
    render json: {errors: errors}, status: :unprocessable_entity and return unless errors.empty?
    @character.save
    render json: {data: @character}
  end

  private

  def find_character
    unless @character = Character.find_by_id(params[:id])
      error = {message: "Character could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end
  end

  def require_permission
    access_denied unless @character.user == current_user
  end
end
