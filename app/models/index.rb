# frozen_string_literal: true
class Index < ApplicationRecord
  include Concealable
  include Presentable

  has_many :index_posts, inverse_of: :index, dependent: :destroy
  has_many :posts, through: :index_posts, dependent: :destroy
  has_many :index_sections, inverse_of: :index, dependent: :destroy
  belongs_to :user, inverse_of: :indexes, optional: false

  validates :name, presence: true

  # SQL form of Concealable#visible_to?, so lists of indexes can be filtered before pagination.
  # Keep the two in sync.
  scope :visible_to, ->(user) {
    if user.nil?
      where(privacy: :public)
    elsif user.read_only?
      where(privacy: [:public, :registered])
    elsif user.admin?
      all
    else
      where(privacy: [:public, :registered, :full_accounts]).or(where(user_id: user.id))
    end
  }

  def editable_by?(user)
    return false unless user
    return false if user.read_only?
    return true unless authors_locked?
    return true if user.id == user_id
    user.has_permission?(:edit_indexes)
  end
end
