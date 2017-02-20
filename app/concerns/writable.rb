module Writable
  extend ActiveSupport::Concern

  included do
    belongs_to :character
    belongs_to :icon
    belongs_to :user
    belongs_to :character_alias

    attr_accessible :character, :character_id, :user, :user_id, :icon, :icon_id, :content, :created_at, :updated_at, :character_alias_id

    validates_presence_of :user
    validate :character_ownership, :icon_ownership

    def has_icons?
      return user.avatar_id? unless character
      return true if character.default_icon
      return false unless character.galleries.present?
      return character.icons.exists?
    end

    def editable_by?(editor)
      return false unless editor
      editor.id == user_id || editor.admin?
    end

    def word_count
      content.split.size
    end

    def url
      return read_attribute(:url) if has_attribute?(:url)
      icon.try(:url)
    end

    def keyword
      return read_attribute(:keyword) if has_attribute?(:keyword)
      icon.try(:keyword)
    end

    def name
      return character_name unless character_alias_id.present?
      return read_attribute(:alias) if has_attribute?(:alias)
      character_alias.name
    end

    def character_name
      return read_attribute(:name) if has_attribute?(:name)
      character.try(:name)
    end

    def screenname
      return read_attribute(:screenname) if has_attribute?(:screenname)
      character.try(:screenname)
    end

    def username
      return read_attribute(:username) if has_attribute?(:username)
      user.username
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
