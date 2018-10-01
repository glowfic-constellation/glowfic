class User < ApplicationRecord
  include Presentable
  include Permissible

  MIN_USERNAME_LEN = 3
  MAX_USERNAME_LEN = 80
  CURRENT_TOS_VERSION = 20181109

  attr_accessor :password, :password_confirmation
  attr_writer :validate_password

  has_many :icons
  has_many :characters
  has_many :galleries
  has_many :character_groups
  has_many :templates
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', inverse_of: :sender
  has_many :messages, foreign_key: 'recipient_id', inverse_of: :recipient
  has_many :password_resets
  has_many :favorites
  has_many :favoriteds, as: :favorite, class_name: 'Favorite', inverse_of: :favorite
  has_many :posts
  has_many :replies
  has_many :indexes
  has_one :report_view
  belongs_to :avatar, class_name: 'Icon', inverse_of: :user, optional: true
  belongs_to :active_character, class_name: 'Character', inverse_of: :user, optional: true
  has_many :blocks, inverse_of: :blocking_user

  validates :crypted, presence: true
  validates :email,
    presence: { on: :create },
    uniqueness: { allow_blank: true }
  validates :username,
    presence: true,
    uniqueness: true,
    length: { in: MIN_USERNAME_LEN..MAX_USERNAME_LEN, allow_blank: true }
  validates :password,
    length: { minimum: 6, if: :validate_password? },
    confirmation: { if: :validate_password? }
  validates :moiety, format: { with: /\A([0-9A-F]{3}){0,2}\z/i }
  validates :password, :password_confirmation, presence: { if: :validate_password? }

  before_validation :encrypt_password, :strip_spaces
  after_save :clear_password

  scope :ordered, -> { order(username: :asc) }

  nilify_blanks

  def authenticate(password)
    return crypted == crypted_password(password) if salt_uuid.present?
    crypted == old_crypted_password(password)
  end

  def gon_attributes
    {
      :username => username,
      :active_character_id => active_character_id,
      :avatar => avatar.try(:as_json),
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

  def can_interact_with?(user)
    !blocked_interaction_users.include?(user.id)
  end

  def blocked_interaction_users
    blocks = Block.where(block_interactions: true)
    (blocks.where(blocking_user: self).pluck(:blocked_user_id) + blocks.where(blocked_user: self).pluck(:blocking_user_id)).uniq
  end

  private

  def strip_spaces
    self.username = self.username.strip if self.username.present?
  end

  def encrypt_password
    if password.present?
      self.salt_uuid ||= SecureRandom.uuid
      self.crypted = crypted_password(password)
    end
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
end
