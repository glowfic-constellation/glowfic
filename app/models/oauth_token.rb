class OauthToken < ApplicationRecord
  belongs_to :client_application
  belongs_to :user
  validates :token, uniqueness: true
  validates :token, presence: true
  before_validation :generate_keys, on: :create
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
    self.token = OAuth::Helper.generate_key(40)[0, 40]
    self.secret = OAuth::Helper.generate_key(40)[0, 40]
  end
end
