# frozen_string_literal: true
class CharacterGroup < Tag
  validates :name, uniqueness: { scope: [:type, :user] }
  validate :valid_characters, :valid_templates

  private

  def valid_characters
    errors.add(:characters, 'must be yours') if characters.present? && characters.detect { |c| c.user_id != user_id }
  end

  def valid_templates
    errors.add(:templates, 'must be yours') if templates.present? && templates.detect { |t| t.user_id != user_id }
  end
end
