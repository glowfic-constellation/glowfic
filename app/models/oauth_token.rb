class OauthToken < ApplicationRecord
  belongs_to :client_application
  belongs_to :user
  validates :token, uniqueness: true
  validates :token, presence: true
  before_validation :generate_keys, on: :create

  scope :authorized, -> { where.not(authorized_at: nil).where(invalidated_at: nil) }
  attr_accessor :expires_at

  def invalidated?
    invalidated_at != nil
  end

  def invalidate!
    update(invalidated_at: Time.zone.now)
  end

  def authorized?
    !authorized_at.nil? && !invalidated?
  end

  protected

  def generate_keys
    self.token = SecureRandom.hex(20)
    self.secret = SecureRandom.hex(20)
  end
end
