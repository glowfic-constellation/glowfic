class TagTag < ApplicationRecord
  belongs_to :setting, foreign_key: :tagged_id, inverse_of: :tag_tags
  belongs_to :canon, foreign_key: :tag_id, inverse_of: :tag_tags
end
