class CharacterGroup < Tag
  scope :owned_by, ->(user) {
    left_outer_joins(character_tags: :character)
      .left_outer_joins(:template_tags)
      .joins('LEFT OUTER JOIN characters ON characters.template_id = template_tags.template_id')
      .where(characters: { user_id: user.id })
  }
end
