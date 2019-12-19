class ContinuityView < ApplicationRecord
  belongs_to :continuity, optional: false
  belongs_to :user, optional: false

  validates :continuity, uniqueness: { scope: :user }
end
