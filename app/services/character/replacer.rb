class Character::Replacer < Generic::Replacer
  attr_reader :alt_dropdown, :success_msg

  def initialize(character)
    @character = character
    super()
  end

  def setup(no_icon_url)
    super
    @alt_dropdown = construct_dropdown
  end

  def replace(params, user:)
    new_char = check_target(params[:icon_dropdown], user: user)
    return if @errors.present?

    orig_alias = check_alias(params[:orig_alias], state: 'old') if params[:orig_alias] != 'all'
    new_alias = check_alias(params[:alias_dropdown], character: new_char, state: 'new')
    return if @errors.present?

    @success_msg = params[:post_ids].present? ? " in the specified " + 'post'.pluralize(params[:post_ids].size) : ''

    wheres = { character_id: @character.id }
    wheres[:post_id] = params[:post_ids] if params[:post_ids].present?
    wheres[:character_alias_id] = orig_alias.try(:id) if @character.aliases.exists? && params[:orig_alias] != 'all'

    updates = { character_id: new_char.try(:id) }
    updates[:character_alias_id] = new_alias.id if new_alias.present?

    replace_jobs(wheres: wheres, updates: updates, post_ids: params[:post_ids])
  end

  private

  def find_alts
    if @character.template
      alts = @character.template.characters
    else
      alts = @character.user.characters.where(template_id: nil)
    end
    alts -= [@character] unless @alts.size <= 1 || @character.aliases.exists?
    alts
  end

  def construct_gallery(no_icon_url)
    icons = @alts.map do |alt|
      if alt.default_icon.present?
        [alt.id, { url: alt.default_icon.url, keyword: alt.default_icon.keyword, aliases: alt.aliases.as_json }]
      else
        [alt.id, { url: no_icon_url, keyword: 'No Icon', aliases: alt.aliases.as_json }]
      end
    end
    gallery = icons.to_h
    gallery[''] = { url: no_icon_url, keyword: 'No Character' }
    gallery
  end

  def construct_dropdown
    @alts.map do |alt|
      name = alt.name
      name += ' | ' + alt.screenname if alt.screenname
      name += ' | ' + alt.template_name if alt.template_name
      name += ' | ' + alt.settings.pluck(:name).join(' & ') if alt.settings.present?
      [name, alt.id]
    end
  end

  def find_posts
    super({character_id: @character.id})
  end

  def check_target(id, user:)
    @errors.add(:character, "could not be found.") unless id.blank? || (new_char = Character.find_by(id: id))
    @errors.add(:base, "You do not have permission to modify this character.") if new_char && new_char.user_id != user.id
    new_char
  end

  def check_alias(alias_id, character: @character, state:)
    return unless alias_id.present?
    alias_obj = CharacterAlias.find_by(id: alias_id)
    @errors.add(:base, "Invalid #{state} alias.") unless alias_obj && alias_obj.character_id == character.id
    alias_obj
  end
end
