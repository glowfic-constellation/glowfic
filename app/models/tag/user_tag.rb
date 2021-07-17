class Tag::UserTag < ApplicationRecord
  self.table_name = 'user_tags'

  belongs_to :user, inverse_of: :user_tags, optional: false
  belongs_to :tag, optional: false
  belongs_to :access_circle, foreign_key: :tag_id, inverse_of: :user_tags, optional: true

  validates :user, uniqueness: { scope: :tag }
end
