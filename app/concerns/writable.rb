module Writable
  extend ActiveSupport::Concern

  included do
    belongs_to :character
    belongs_to :icon
    belongs_to :user

    attr_accessible :character, :character_id, :user, :user_id, :icon, :icon_id, :content, :created_at, :updated_at

    validates_presence_of :user, :content
    validate :character_ownership, :icon_ownership

    before_save :clean_html

    def has_icons?
      return user.avatar_id? unless character
      return false unless character.gallery
      return character.gallery.icons.present?
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

    def clean_html
      self.content = Nokogiri::HTML.parse(self.content).at('body').inner_html
    end
  end
end
