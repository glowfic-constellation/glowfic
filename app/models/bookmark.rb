# frozen_string_literal: true
class Bookmark < ApplicationRecord
  belongs_to :user, inverse_of: :bookmarks, optional: false
  belongs_to :reply, inverse_of: :bookmarks, optional: false
  belongs_to :post, inverse_of: :bookmarks, optional: false

  validates :type, uniqueness: { scope: [:user, :reply] }
  validates :type, inclusion: { in: ['reply_bookmark'] }, allow_nil: false

  self.inheritance_column = nil

  scope :_visible_user, ->(user) { where(user_id: user&.id).joins(:user).or(where(user: { public_bookmarks: true })) }
  scope :_visible_post, ->(user) { where(post_id: Post.visible_to(user).select(:id)) }
  scope :visible_to, ->(user) { _visible_user(user)._visible_post(user) }

  def visible_to?(other_user)
    return false unless other_user
    return false unless post.visible_to?(other_user)
    return false unless reply
    return true if other_user.id == user.id
    user.public_bookmarks
  end
end
