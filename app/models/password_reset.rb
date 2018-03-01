class PasswordReset < ApplicationRecord
  belongs_to :user, inverse_of: :password_resets, optional: false

  validates :auth_token, presence: true, uniqueness: true

  before_validation :generate_unique_auth_token

  scope :active, -> { where('created_at > ?', 1.day.ago) }
  scope :unused, -> { where(used: false) }

  def active?
    created_at > 1.day.ago
  end

  private

  def generate_unique_auth_token
    return if auth_token.present?
    return unless user
    loop do
      self.auth_token = generate_auth_token
      break unless self.class.where(auth_token: self.auth_token).exists?
    end
  end

  def generate_auth_token
    id_hash = Digest::SHA1.hexdigest(user.id.to_s)[0..5]
    SecureRandom.urlsafe_base64 + id_hash
  end
end
