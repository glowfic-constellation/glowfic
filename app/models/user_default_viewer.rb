# frozen_string_literal: true
class UserDefaultViewer < ApplicationRecord
  belongs_to :user, inverse_of: :user_default_viewers, optional: false
  belongs_to :viewer, class_name: 'User', inverse_of: false, optional: false

  validates :user_id, uniqueness: { scope: :viewer_id }
  validate :no_self_default

  private

  def no_self_default
    errors.add(:viewer_id, "can't be the user themselves") if viewer_id == user_id
  end
end
