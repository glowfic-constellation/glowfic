# frozen_string_literal: true
class User::Bookmark < ApplicationRecord
  belongs_to :user, inverse_of: :user_bookmarks, optional: false
  belongs_to :reply, inverse_of: :user_bookmarks, optional: false
  belongs_to :post, inverse_of: :user_bookmarks, optional: false

  validates :type, uniqueness: { scope: [:user, :reply] }
  validates :type, inclusion: { in: ['reply_bookmark'] }, allow_nil: false
end
