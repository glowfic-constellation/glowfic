# frozen_string_literal: true
class Index < ApplicationRecord
  include Concealable

  has_many :index_posts, inverse_of: :index, dependent: :destroy
  has_many :posts, through: :index_posts, dependent: :destroy
  has_many :index_sections, inverse_of: :index, dependent: :destroy
  belongs_to :user, inverse_of: :indexes, optional: false

  validates :name, presence: true

  # keep in sync with Concealable#visible_to?
  scope :visible_to, ->(user) {
    return where(privacy: :public) unless user
    return all if user.admin?

    privacies = [:public, :registered]
    return where(privacy: privacies) if user.read_only?
    where(privacy: privacies + [:full_accounts]).or(where(user_id: user.id))
  }

  def editable_by?(user)
    return false unless user
    return false if user.read_only?
    return false unless visible_to?(user)
    return true unless authors_locked?
    return true if user.id == user_id
    user.has_permission?(:edit_indexes)
  end
end
