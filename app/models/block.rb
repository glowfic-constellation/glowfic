class Block < ApplicationRecord
  belongs_to :blocking_user, class_name: 'User', optional: false
  belongs_to :blocked_user, class_name: 'User', optional: false
end
