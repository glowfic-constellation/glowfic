class Setting < Tag
  include Taggable

  has_many :tag_tags, foreign_key: :tagged_id, inverse_of: :setting
  has_many :canons, through: :tag_tags

  acts_as_tag :canon
end
