class Canon < Tag
  has_many :tag_tags, foreign_key: :tag_id, inverse_of: :canon
  has_many :settings, through: :tag_tags

  def has_items?
    return true if super
    settings.count > 0
  end
end
