module Writable
  extend ActiveSupport::Concern

  included do
    belongs_to :character
    belongs_to :icon
    belongs_to :user

    attr_accessible :character, :character_id, :user, :user_id, :icon, :icon_id, :content, :created_at, :updated_at

    validates_presence_of :user, :content
    validate :character_ownership, :icon_ownership

    def has_icons?
      return user.avatar_id? unless character
      return true if character.icon
      return false unless character.gallery
      return character.gallery.icons.present?
    end

    def editable_by?(editor)
      return false unless editor
      editor.id == user_id || editor.admin?
    end

    private

    def character_ownership
      return true unless character
      return true if character.user_id == user_id
      errors.add(:character, "must be yours")
    end

    def icon_ownership
      return true unless icon
      return true if icon.user_id == user_id
      errors.add(:icon, "must be yours")
    end
  end
end
