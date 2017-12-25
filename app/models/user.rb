class User < ApplicationRecord
  include Presentable
  include Permissible

  MIN_USERNAME_LEN = 3
  MAX_USERNAME_LEN = 80

  attr_accessor :password, :password_confirmation
  attr_writer :validate_password

  has_many :icons
  has_many :characters
  has_many :galleries
  has_many :character_groups
  has_many :templates
  has_many :sent_messages, :class_name => Message, :foreign_key => 'sender_id'
  has_many :messages, :foreign_key => 'recipient_id'
  has_many :password_resets
  has_many :favorites
  has_many :favoriteds, as: :favorite, class_name: Favorite
  has_many :posts
  has_many :replies
  has_many :indexes
  has_one :report_view
  belongs_to :avatar, :class_name => Icon, optional: true
  belongs_to :active_character, :class_name => Character, optional: true

  validates_presence_of :username, :crypted
  validates_presence_of :email, on: :create
  validates_uniqueness_of :username
  validates_uniqueness_of :email, allow_blank: true
  validates_length_of :username, :in => MIN_USERNAME_LEN..MAX_USERNAME_LEN, :allow_blank => true
  validates_length_of :moiety, in: 3..6, allow_blank: true
  validates_length_of :password, minimum: 6, if: :validate_password?
  validates_confirmation_of :password, if: :validate_password?
  validates_presence_of :password, :password_confirmation, if: :validate_password?

  before_validation :encrypt_password
  after_save :clear_password

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
    icons.where(has_gallery: false).order('LOWER(keyword)')
  end

  def default_view
    super || 'icon'
  end

  private

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
