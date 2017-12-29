class PostSetting < ApplicationRecord
  belongs_to :post, inverse_of: :post_settings, optional: false
  belongs_to :setting, inverse_of: :post_settings, optional: false
end
