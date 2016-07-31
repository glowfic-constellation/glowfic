class Tag < ActiveRecord::Base
  belongs_to :user
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags
  has_many :character_tags, dependent: :destroy
  has_many :characters, through: :character_tags

  validates_presence_of :user, :name
  validates :name, uniqueness: { scope: :type }

  def editable_by?(user)
    user.try(:admin?)
  end

  def as_json(*args, **kwargs)
    {id: self.id, text: self.name}
  end
end
