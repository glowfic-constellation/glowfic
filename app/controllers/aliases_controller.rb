class AliasesController < CrudController # TODO create and destroy go to edit_character_path(@character)
  before_action :find_character

  private

  def set_params(char_alias)
    char_alias.character = @character
  end

  def find_character
    unless (@character = Character.find_by_id(params[:character_id]))
      flash[:error] = "Character could not be found."
      redirect_to user_characters_path(current_user) and return
    end

    unless @character.user == current_user
      flash[:error] = "That is not your character."
      redirect_to user_characters_path(current_user) and return
    end
  end

  def find_model
    super
    unless @model.character_id == @character.id
      flash[:error] = "Alias could not be found for that character."
      redirect_to edit_character_path(@character) and return
    end
  end

  def model_params
    params.fetch(:character_alias, {}).permit(:name)
  end

  def model_class
    CharacterAlias
  end
end
