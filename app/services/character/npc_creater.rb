# frozen_string_literal: true
class Character::NpcCreater < Object
  def initialize(writable, char_params)
    @writable = writable
    @params = char_params
  end

  def process
    return @writable unless @writable.character.nil? && @params[:npc] == 'true'

    # we take the NPC's first post's subject as its nickname, for disambiguation in dropdowns etc
    # additionally, we grab the post's settings and attach those to the character
    post = @writable.is_a?(Post) ? @writable : @writable.post

    @writable.build_character(
      @params.merge(
        default_icon_id: @writable.icon_id,
        user_id: @writable.user_id,
        nickname: post.subject,
        settings: post.settings,
      ),
    )
    @writable
  end
end
