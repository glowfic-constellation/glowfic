# frozen_string_literal: true
class User < ApplicationRecord
  include Blockable
  include Presentable
  include Permissible

  MIN_USERNAME_LEN = 3
  MAX_USERNAME_LEN = 80
  MIN_PASSWORD_LEN = 6
  CURRENT_TOS_VERSION = 20181109
  RESERVED_NAMES = ['(deleted user)', 'Glowfic Constellation']

  attr_accessor :password, :password_confirmation
  attr_writer :validate_password

  has_many :icons
  has_many :characters
  has_many :galleries
  has_many :character_groups
  has_many :templates
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', inverse_of: :sender
  has_many :messages, foreign_key: 'recipient_id', inverse_of: :recipient
  has_many :notifications, inverse_of: :user
  has_many :password_resets
  has_many :favorites
  has_many :favoriteds, as: :favorite, class_name: 'Favorite', inverse_of: :favorite
  has_many :posts
  has_many :replies
  has_many :indexes
  has_many :news
  has_one :report_view
  belongs_to :avatar, class_name: 'Icon', inverse_of: :user, optional: true
  belongs_to :active_character, class_name: 'Character', inverse_of: :user, optional: true

  has_many :user_tags, inverse_of: :user, dependent: :destroy
  has_many :content_warnings, -> { ordered_by_user_tag }, through: :user_tags, source: :content_warning, dependent: :destroy

  has_many :bookmarks, inverse_of: :user, dependent: :destroy
  has_many :bookmarked_replies, through: :bookmarks, source: :reply, dependent: :destroy
  has_many :bookmarked_posts, -> { ordered }, through: :bookmarks, source: :post, dependent: :destroy

  validates :crypted, presence: true
  validates :email,
    presence: { on: :create },
    uniqueness: { allow_blank: true }
  validates :username,
    presence: true,
    uniqueness: true,
    length: { in: MIN_USERNAME_LEN..MAX_USERNAME_LEN, allow_blank: true }
  validates :password,
    length: { minimum: MIN_PASSWORD_LEN, if: :validate_password? },
    confirmation: { if: :validate_password? }
  validates :moiety, format: { with: /\A([0-9A-F]{3}){0,2}\z/i }, length: { maximum: 255 }
  validates :moiety_name, length: { maximum: 255 }
  validates :profile_editor_mode, inclusion: { in: ['html', 'rtf', 'md'] }, allow_nil: true
  validates :password, :password_confirmation, presence: { if: :validate_password? }
  validate :username_not_reserved

  before_validation :encrypt_password, :strip_spaces
  after_update :update_flat_posts
  after_save :clear_password

  scope :ordered, -> { order(username: :asc) }
  scope :active, -> { where(deleted: false) }
  scope :full, -> { where.not(role_id: Permissible::READONLY).or(where(role_id: nil)) }

  nilify_blanks

  def authenticate(password)
    return crypted == crypted_password(password) if salt_uuid.present?
    crypted == old_crypted_password(password)
  end

  def gon_attributes
    {
      username: username,
      active_character_id: active_character_id,
      avatar: avatar.try(:as_json),
    }
  end

  def writes_in?(continuity)
    continuity.open_to?(self)
  end

  def galleryless_icons
    icons.where(has_gallery: false).ordered
  end

  def default_view
    super || 'icon'
  end

  def layout_darkmode?
    return false unless layout
    layout.include?('dark')
  end

  def archive
    User.transaction do
      self.update!(email_notifications: false, deleted: true, favorite_notifications: false)
      Setting.where(user_id: self.id).where(owned: true).find_each do |setting|
        setting.update!(owned: false)
      end
      Block.where(blocking_user: self).or(Block.where(blocked_user: self)).destroy_all
    end
  end

  def visible_posts
    Rails.cache.fetch(PostViewer.cache_string_for(self.id), expires_in: 1.month) do
      viewer_post_ids = PostViewer.where(user: self).pluck(:post_id)
      circle_ids = user_tags.pluck(:tag_id)
      circle_post_ids = PostTag.where(tag_id: circle_ids).select(:post_id).distinct.pluck(:post_id)
      (viewer_post_ids + circle_post_ids).uniq
    end
  end

  def blocked_posts
    blocks = Block.where(blocked_user_id: self.id)
    posts_blockers = blocks.where(hide_me: :posts).pluck(:blocking_user_id)
    full_blockers = blocks.where(hide_me: :all).pluck(:blocking_user_id)
    blocked_or_hidden_posts('blocked', posts_blockers, full_blockers)
  end

  def hidden_posts
    blocks = Block.where(blocking_user_id: self.id)
    posts_blocked = blocks.where(hide_them: :posts).pluck(:blocked_user_id)
    full_blocked = blocks.where(hide_them: :all).pluck(:blocked_user_id)
    blocked_or_hidden_posts('hidden', posts_blocked, full_blocked)
  end

  private

  def strip_spaces
    self.username = self.username.strip if self.username.present?
  end

  def encrypt_password
    return unless password.present?
    self.salt_uuid ||= SecureRandom.uuid
    self.crypted = crypted_password(password)
  end

  def crypted_password(unencrypted)
    crypted = "Adding #{salt_uuid} to #{unencrypted}"
    17.times { crypted = Digest::SHA1.hexdigest(crypted) }
    crypted
  end

  def old_crypted_password(unencrypted)
    crypted = "Adding #{old_salt} to #{unencrypted}"
    17.times { crypted = Digest::SHA1.hexdigest(crypted) }
    crypted
  end

  def old_salt
    "1d0e9f00dc7#{username.to_s.downcase}dda7264ec524b051e434f4dda9ecfef8891004efe56fbff6a0"
  end

  def clear_password
    self.password = nil
    self.password_confirmation = nil
  end

  def validate_password?
    !!@validate_password
  end

  def username_not_reserved
    return unless self.username.present?
    return unless RESERVED_NAMES.include?(self.username)
    errors.add(:username, 'is invalid')
  end

  def blocked_or_hidden_posts(keyword, post_user_ids, full_user_ids)
    Rails.cache.fetch(Block.cache_string_for(self.id, keyword), expires_in: 1.month) do
      all_user_ids = (post_user_ids + full_user_ids).uniq
      post_ids = Post.unscoped.where(
        authors_locked: true,
        id: Post::Author.where(user_id: all_user_ids).select(:post_id),
      ).pluck(:id)
      if keyword == 'blocked'
        post_ids -= Post::Author.where(user_id: self.id).pluck(:post_id)
      else
        full_ids = Post::Author.where(user_id: full_user_ids).pluck(:post_id)
        full_ids -= Post::Author.where(user_id: self.id).pluck(:post_id)
        post_ids += full_ids
        post_ids.uniq!
      end
      post_ids
    end
  end

  def update_flat_posts
    return unless saved_change_to_username? || saved_change_to_deleted?
    post_ids = Post::Author.where(user_id: id).pluck(:post_id)
    post_ids.each { |id| GenerateFlatPostJob.enqueue(id) }
  end
end
