# frozen_string_literal: true
class Favorite < ApplicationRecord
  belongs_to :user, inverse_of: :favorites, optional: false
  belongs_to :favorite, polymorphic: true, optional: false

  validates :user_id, uniqueness: { scope: [:favorite_id, :favorite_type] }
  validate :not_yourself

  def self.between(user, favorite)
    return unless user && favorite
    Favorite.find_by(user_id: user.id, favorite_id: favorite.id, favorite_type: favorite.class.to_s)
  end

  private

  def not_yourself
    return unless favorite_type == User.to_s
    return unless favorite_id == user_id
    errors.add(:user, "cannot favorite themself")
  end
end
