class Block < ApplicationRecord
  belongs_to :blocking_user, class_name: 'User', optional: false, inverse_of: blocks
  belongs_to :blocked_user, class_name: 'User', optional: false
end
