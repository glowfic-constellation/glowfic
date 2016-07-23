module Writable
  extend ActiveSupport::Concern

  included do
    belongs_to :character
    belongs_to :icon
    belongs_to :user

    attr_accessible :character, :character_id, :user, :user_id, :icon, :icon_id, :content, :created_at, :updated_at

    validates_presence_of :user
    validate :character_ownership, :icon_ownership

    def has_icons?
      return user.avatar_id? unless character
      return true if character.default_icon
      return false unless character.gallery
      return character.galleries.map(&:icons).present?
    end

    def editable_by?(editor)
      return false unless editor
      editor.id == user_id || editor.admin?
    end

    def word_count
      content.split.size
    end

    private

    def character_ownership
      return true unless character_id_changed?
      return true unless character
      return true if character.user_id == user_id
      errors.add(:character, "must be yours")
    end

    def icon_ownership
      return true unless icon_id_changed?
      return true unless icon
      return true if icon.user_id == user_id
      errors.add(:icon, "must be yours")
    end
  end
end
