class TagTag < ApplicationRecord
  belongs_to :child_setting, class_name: Setting, foreign_key: :tagged_id, inverse_of: :child_setting_tags
  belongs_to :parent_setting, class_name: Setting, foreign_key: :tag_id, inverse_of: :parent_setting_tags
end
