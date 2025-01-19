# frozen_string_literal: true
class Character::NpcCreater < Object
  def initialize(writable, params)
  end

  def process_npc(writable, permitted_character_params)
    return unless writable.character.nil?
    return unless permitted_character_params[:npc] == 'true'

    # we take the NPC's first post's subject as its nickname, for disambiguation in dropdowns etc
    # additionally, we grab the post's settings and attach those to the character
    post = if writable.is_a? Post
      writable
    else
      writable.post
    end

    writable.build_character(
      permitted_character_params.merge(
        default_icon_id: writable.icon_id,
        user_id: writable.user_id,
        nickname: post.subject,
        settings: post.settings,
      ),
    )
  end
end
