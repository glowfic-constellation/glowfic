class PasswordReset < ActiveRecord::Base
  belongs_to :user, inverse_of: :password_resets

  validates_presence_of :user, :auth_token
  validates_uniqueness_of :auth_token

  before_validation :generate_auth_token

  scope :active, lambda{ where('created_at > ?', 1.day.ago) }
  scope :unused, where(used: false)

  def active?
    created_at > 1.day.ago
  end

  private

  def generate_auth_token
    return if auth_token.present?
    return unless user
    id_hash = Digest::SHA1.hexdigest(user.id.to_s)[0..5]
    self.auth_token = SecureRandom.urlsafe_base64 + id_hash
    while self.class.where(auth_token: self.auth_token).exists?
      self.auth_token = SecureRandom.urlsafe_base64 + id_hash
    end
  end
end
