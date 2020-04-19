module CharacterSplit
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
  included { helper_method :character_split }
end
