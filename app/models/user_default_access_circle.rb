# frozen_string_literal: true
class UserDefaultAccessCircle < ApplicationRecord
  belongs_to :user, inverse_of: :user_default_access_circles, optional: false
  belongs_to :access_circle, foreign_key: :tag_id, inverse_of: :user_default_access_circles, optional: false

  validates :user_id, uniqueness: { scope: :tag_id }
end
