# frozen_string_literal: true
module CharacterFilter
  extend ActiveSupport::Concern

  # logic replicated from page_view
  def character_split
    return @character_split if @character_split
    if logged_in?
      @character_split = params[:character_split] || current_user.default_character_split
    else
      @character_split = session[:character_split] = params[:character_split] || session[:character_split] || 'template'
    end
  end

  def show_retired
    return @show_retired if @show_retired
    if logged_in?
      @show_retired = params.fetch(:retired, (!current_user.default_hide_retired_characters).to_s) != 'false'
    else
      @show_retired = session.fetch(:retired, params.fetch(:retired, 'true')) != 'false'
    end
  end

  included do
    helper_method :character_split
    helper_method :show_retired
  end
end
