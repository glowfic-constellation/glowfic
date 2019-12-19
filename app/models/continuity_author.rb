class ContinuityAuthor < ApplicationRecord
  belongs_to :continuity, optional: false
  belongs_to :user, optional: false

  validates :user_id, uniqueness: { scope: :continuity_id }
end
