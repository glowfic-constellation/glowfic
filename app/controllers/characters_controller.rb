class CharactersController < ApplicationController
  before_filter :login_required
  before_filter :find_character, :only => [:show, :destroy]

  def index
    @characters = current_user.characters
  end

  def new
    @character = Character.new
  end

  def create
    @character = Character.new(params[:character])
    @character.user = current_user
    if @character.save
      flash[:success] = "Character saved successfully."
      redirect_to characters_path
    else
      flash[:error] = "Your character could not be saved."
      render :action => :new
    end
  end

  def show
  end

  def update
  end

  def destroy
    @character.destroy
    flash[:success] = "Character deleted successfully."
    redirect_to characters_path
  end

  private

  def find_character
    @character = Character.find_by_id(params[:id])

    unless @character
      flash[:error] = "Character could not be found."
      redirect_to characters_path and return
    end

    if @character.user_id != current_user.id
      flash[:error] = "That is not your character."
      redirect_to characters_path and return
    end
  end
end
