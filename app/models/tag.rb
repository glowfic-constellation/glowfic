class Tag < ActiveRecord::Base
  belongs_to :user
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates_presence_of :user, :name

  def editable_by?(user)
    return false unless user
    return true if user.admin?
    user.id == user_id
  end
end
