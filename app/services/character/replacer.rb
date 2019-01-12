class Character::Replacer < Generic::Replacer
  attr_reader :alt_dropdown, :success_msg

  def initialize(character)
    @character = character
    super()
  end

  def setup(no_icon_url)
    if @character.template
      @alts = @character.template.characters
    else
      @alts = @character.user.characters.where(template_id: nil)
    end
    @alts -= [@character] unless @alts.size <= 1 || @character.aliases.exists?

    icons = @alts.map do |alt|
      if alt.default_icon.present?
        [alt.id, { url: alt.default_icon.url, keyword: alt.default_icon.keyword, aliases: alt.aliases.as_json }]
      else
        [alt.id, { url: no_icon_url, keyword: 'No Icon', aliases: alt.aliases.as_json }]
      end
    end
    @gallery = icons.to_h
    @gallery[''] = { url: no_icon_url, keyword: 'No Character' }

    @alt_dropdown = @alts.map do |alt|
      name = alt.name
      name += ' | ' + alt.screenname if alt.screenname
      name += ' | ' + alt.template_name if alt.template_name
      name += ' | ' + alt.settings.pluck(:name).join(' & ') if alt.settings.present?
      [name, alt.id]
    end
    @alt = @alts.first

    reply_post_ids = Reply.where(character_id: @character.id).select(:post_id).distinct.pluck(:post_id)
    all_posts = Post.where(character_id: @character.id) + Post.where(id: reply_post_ids)
    @posts = all_posts.uniq
  end

  def replace(params, user:)
    unless params[:icon_dropdown].blank? || (new_char = Character.find_by_id(params[:icon_dropdown]))
      @errors.add(:character, "could not be found.")
    end

    if new_char && new_char.user_id != current_user.id
      @errors.add(:base, "You do not have permission to modify this character.") && return
    end

    orig_alias = nil
    if params[:orig_alias].present? && params[:orig_alias] != 'all'
      orig_alias = CharacterAlias.find_by_id(params[:orig_alias])
      @errors.add(:base, "Invalid old alias.") unless orig_alias && orig_alias.character_id == @character.id
    end

    new_alias_id = nil
    if params[:alias_dropdown].present?
      new_alias = CharacterAlias.find_by_id(params[:alias_dropdown])
      @errors.add(:base, "Invalid new alias.") unless new_alias && new_alias.character_id == new_char.try(:id)
      new_alias_id = new_alias.id
    end

    @success_msg = ''
    wheres = { character_id: @character.id }
    updates = { character_id: new_char.try(:id), character_alias_id: new_alias_id }

    if params[:post_ids].present?
      wheres[:post_id] = params[:post_ids]
      @success_msg = " in the specified " + 'post'.pluralize(params[:post_ids].size)
    end

    wheres[:character_alias_id] = orig_alias.try(:id) if @character.aliases.exists? && params[:orig_alias] != 'all'

    UpdateModelJob.perform_later(Reply.to_s, wheres, updates)
    wheres[:id] = wheres.delete(:post_id) if params[:post_ids].present?
    UpdateModelJob.perform_later(Post.to_s, wheres, updates)
  end
end
