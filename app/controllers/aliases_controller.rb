# frozen_string_literal: true
class AliasesController < ApplicationController
  before_action :login_required
  before_action :require_permission
  before_action :find_character
  before_action :find_model, only: :destroy

  def new
    @page_title = t('.title', name: @character.name)
    @alias = CharacterAlias.new(character: @character)
  end

  def create
    @alias = CharacterAlias.new(permitted_params)
    @alias.character = @character

    begin
      @alias.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@alias, action: 'created', now: true, class_name: 'Alias', err: e)

      @page_title = t('aliases.new.title', name: @character.name)
      render :new
    else
      flash[:success] = t('.success')
      redirect_to edit_character_path(@character)
    end
  end

  def destroy
    begin
      @alias.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@alias, action: 'deleted', class_name: 'Alias', err: e)
    else
      flash[:success] = t('.success')
    end
    redirect_to edit_character_path(@character)
  end

  private

  def require_permission
    return unless current_user&.read_only?
    flash[:error] = t('aliases.errors.no_permission.create')
    redirect_to continuities_path
  end

  def find_character
    unless (@character = Character.find_by_id(params[:character_id]))
      flash[:error] = t('aliases.errors.parent_not_found')
      redirect_to user_characters_path(current_user) and return
    end

    return if @character.user == current_user
    flash[:error] = t('characters.errors.no_permission.edit')
    redirect_to user_characters_path(current_user)
  end

  def find_model
    unless (@alias = CharacterAlias.find_by_id(params[:id]))
      flash[:error] = t('aliases.errors.not_found')
      redirect_to edit_character_path(@character) and return
    end

    return if @alias.character_id == @character.id

    flash[:error] = t('aliases.errors.not_matched')
    redirect_to edit_character_path(@character)
  end

  def permitted_params
    params.fetch(:character_alias, {}).permit(:name)
  end
end
