# frozen_string_literal: true
class Admin::CharactersController < Admin::AdminController
  before_action :require_relocate_permission, only: [:relocate, :do_relocate]

  def relocate
    @page_title = 'Reassign Character'
  end

  def do_relocate
    @char_ids = params[:character_id]&.split(',')&.map(&:strip)&.map(&:to_i)
    @characters = Character.where(id: @char_ids)
    @new_user = User.find_by(id: params[:user_id])
    unless @new_user.present?
      flash[:error] = "New user could not be found."
      redirect_to relocate_characters_url and return
    end
    unless @characters.present?
      flash[:error] = "Characters could not be found."
      redirect_to relocate_characters_url and return
    end

    preview_relocate and return if params[:button_preview].present?

    relocator = Character::Relocator.new(current_user.id)
    begin
      relocator.transfer(@char_ids, params[:user_id], include_templates: params[:include_templates])
    rescue CharacterGroupError
      flash[:error] = "Characters must not have groups."
      redirect_to relocate_characters_url and return
    rescue RequireSingleUser
      flash[:error] = "Characters must have a single original user."
      redirect_to relocate_characters_url and return
    rescue ApiError => e
      flash[:error] = e.message
      redirect_to relocate_characters_url and return
    else
      flash[:success] = "Characters relocated."
      redirect_to admin_url
    end
  end

  private

  def preview_relocate
    @page_title = 'Preview Character Reassignment'
    render :preview_relocate
  end

  def require_relocate_permission
    return if current_user.has_permission?(:relocate_characters)
    flash[:error] = "You do not have permission to view that page."
    redirect_to admin_url
  end
end
