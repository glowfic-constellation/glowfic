class Index < ApplicationRecord
  include Concealable

  has_many :index_posts, inverse_of: :index, dependent: :destroy
  has_many :posts, through: :index_posts, dependent: :destroy
  has_many :index_sections, inverse_of: :index, dependent: :destroy
  belongs_to :user, inverse_of: :indexes, optional: false

  validates :name, presence: true

  def editable_by?(user)
    return false unless user
    return true if open_to_anyone?
    return true if user.id == user_id
    user.has_permission?(:edit_indexes)
  end
end
