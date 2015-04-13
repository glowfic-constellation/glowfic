class User < ActiveRecord::Base
  attr_accessor :password
  attr_protected :crypted

  validates_presence_of :username
  validates_uniqueness_of :username
  validates_length_of :username, :in => 2..80, :allow_blank => true
  validates_length_of :password, :in => 6..25, :on => :create
  validates_confirmation_of :password, :on => :create
  validate :password_present

  before_save :encrypt_password
  after_save :clear_password

  def authenticate(password)
    crypted == crypted_password(password)
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