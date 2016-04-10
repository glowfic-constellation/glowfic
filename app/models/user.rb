class User < ActiveRecord::Base
  MIN_USERNAME_LEN = 3
  MAX_USERNAME_LEN = 80

  attr_accessor :password, :password_confirmation
  attr_protected :crypted

  has_many :icons
  has_many :characters
  has_many :galleries
  has_many :character_groups
  has_many :templates
  has_many :sent_messages, :class_name => Message, :foreign_key => 'sender_id'
  has_many :messages, :foreign_key => 'recipient_id'
  belongs_to :avatar, :class_name => Icon
  belongs_to :active_character, :class_name => Character

  validates_presence_of :username
  validates_uniqueness_of :username
  validates_uniqueness_of :email, allow_blank: true
  validates_length_of :username, :in => MIN_USERNAME_LEN..MAX_USERNAME_LEN, :allow_blank => true
  validates_length_of :password, :in => 6..25, :on => :create
  validates_length_of :moiety, in: 3..6, allow_blank: true
  validates_confirmation_of :password, :on => :create
  validate :password_present

  before_save :encrypt_password
  after_save :clear_password

  nilify_blanks

  def authenticate(password)
    crypted == crypted_password(password)
  end

  def avatar=(val)
    write_attribute(:avatar_id, val.id) and return if val.is_a?(Icon)
    self.avatar_id = nil and return unless val.present?
    self.avatar.update_attributes(url: val) and return if self.avatar # TODO nope make new or update existing
    self.avatar_id = Icon.create(user: self, url: val, keyword: 'Avatar').id
  end

  def gon_attributes
    { 
      :username => username, 
      :active_character_id => active_character_id, 
      :avatar => { :id => avatar.try(:id), :url => avatar.try(:url) },
    }
  end

  def writes_in?(continuity)
    continuity.open_to?(self)
  end

  def admin?
    id == 1
  end

  def galleryless_icons
    icons.where(has_gallery: false)
  end

  def default_view
    super || 'icon'
  end

  private

  def password_present
    return true if password.present? || crypted.present?
    errors.add(:password, "can't be blank")
  end

  def encrypt_password
    self.crypted = crypted_password(password) if password.present?
  end

  def crypted_password(unencrypted)
    crypted = "Adding #{salt} to #{unencrypted}"
    17.times { crypted = Digest::SHA1.hexdigest(crypted) }
    crypted
  end

  def salt
    "1d0e9f00dc7#{username.to_s.downcase}dda7264ec524b051e434f4dda9ecfef8891004efe56fbff6a0"
  end

  def clear_password
    self.password = nil
    self.password_confirmation = nil
  end
end
