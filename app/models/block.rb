class Block < ApplicationRecord
  belongs_to :blocking_user, class_name: 'User', optional: false, inverse_of: blocks
  belongs_to :blocked_user, class_name: 'User', optional: false

  validates :blocking_user_id, uniqueness: { scope: :blocked_user_id }
end
