module Writable
  extend ActiveSupport::Concern

  included do
    belongs_to :character
    belongs_to :icon
    belongs_to :user

    attr_accessible :character, :character_id, :user, :user_id, :icon, :icon_id, :content

    validates_presence_of :user, :content
  end
end
