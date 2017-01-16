class Api::V1::CharactersController < Api::ApiController
  def show
    unless character = Character.find_by_id(params[:id])
      error = {message: "Character could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    render json: {data: CharacterPresenter.new(character)}
  end
end
